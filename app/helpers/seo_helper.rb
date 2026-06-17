module SeoHelper
  TEXT_BLOCK_TYPES = %w[
    paragraph
    heading_1
    heading_2
    heading_3
    bulleted_list_item
    numbered_list_item
    quote
    callout
    toggle
  ].freeze

  NOINDEX_CONTROLLER_PATHS = %w[
    sessions
    registrations
    passwords
    search
  ].freeze

  def seo_title(page_title = nil)
    page_title = page_title.presence

    if page_title.blank?
      t("site.app_name")
    elsif home_page? || page_title == t("site.name")
      "#{t('site.name')} — #{t('home.tagline')}"
    else
      "#{page_title} | #{t('site.name')}"
    end
  end

  def seo_description(text)
    text.to_s.squish.truncate(160)
  end

  def seo_canonical_url
    uri = URI.parse(request.original_url)
    uri.query = nil
    uri.fragment = nil
    uri.to_s
  end

  def seo_default_image_url
    image_url("profile.jpg")
  end

  def seo_cover_image_url(record)
    return seo_default_image_url if record.blank?

    if record.respond_to?(:cover_url) && record.cover_url.present?
      return record.cover_url
    end

    attachment =
      if record.respond_to?(:cover_for_display)
        record.cover_for_display
      elsif record.respond_to?(:cover_attachment)
        record.cover_attachment
      end

    if attachment&.image?
      url_for(display_image(attachment, size: :full))
    else
      seo_default_image_url
    end
  end

  def notion_body_excerpt(record, limit: 160)
    return if record.blank?

    text = extract_first_text_from_blocks(record.body) if record.respond_to?(:body)
    text = record_seo_fallback(record) if text.blank?
    seo_description(text) if text.present?
  end

  def record_seo_description(record)
    excerpt = notion_body_excerpt(record) if record.respond_to?(:body)
    return excerpt if excerpt.present?

    fallback = record_seo_fallback(record)
    seo_description(fallback) if fallback.present?
  end

  def seo_noindex?
    path = controller.controller_path
    return true if path.start_with?("identity/", "avo/")
    return true if NOINDEX_CONTROLLER_PATHS.include?(path)

    false
  end

  def seo_robots_content
    return content_for(:robots) if content_for?(:robots)

    seo_noindex? ? "noindex, nofollow" : "index, follow"
  end

  def seo_og_locale
    I18n.locale == :ru ? "ru_RU" : "en_US"
  end

  private

    def home_page?
      controller.controller_name == "home" && controller.action_name == "index"
    end

    def record_seo_fallback(record)
      if record.respond_to?(:client) && record.client&.name.present? && record.name.present?
        "#{record.name} — #{record.client.name}"
      elsif record.respond_to?(:name) && record.name.present?
        record.name
      end
    end

    def extract_first_text_from_blocks(blocks)
      Array(blocks).each do |block|
        type = block["type"]

        if TEXT_BLOCK_TYPES.include?(type)
          text = Array(block["rich_text"]).filter_map { |segment| segment["text"] }.join.squish
          return text if text.present?
        elsif type == "column_list"
          Array(block["columns"]).each do |column|
            found = extract_first_text_from_blocks(column["children"])
            return found if found.present?
          end
        elsif block["children"].present?
          found = extract_first_text_from_blocks(block["children"])
          return found if found.present?
        end
      end

      nil
    end
end
