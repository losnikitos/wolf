module NotionPageContent
  extend ActiveSupport::Concern

  MEDIA_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
    image/svg+xml
    video/mp4
    video/webm
    video/quicktime
  ].freeze

  included do
    has_many_attached :media
  end

  def media_for_block(notion_block_id)
    media.find { |attachment| attachment.blob.metadata["notion_block_id"] == notion_block_id }
  end

  def page_content_never_synced?
    page_content_last_synced_at.nil?
  end

  def notion_cover_for_display
    return cover if respond_to?(:cover) && cover.attached?
    return if respond_to?(:cover_url) && cover_url.present?

    nil
  end

  def notion_cover_for_display?
    (respond_to?(:cover) && cover.attached?) ||
      (respond_to?(:cover_url) && cover_url.present?)
  end

  def cover_for_display
    notion_cover_for_display || first_body_media
  end

  def cover_for_display?
    notion_cover_for_display? || first_body_media.present?
  end

  def first_body_media
    find_first_body_media(body)
  end

  private

  def find_first_body_media(blocks)
    Array(blocks).each do |block|
      type = block["type"]

      if NotionBodyParser::MEDIA_BLOCK_TYPES.include?(type)
        attachment = media_for_block(block["id"])
        return attachment if attachment&.image? || attachment&.video?
      elsif type == "column_list"
        Array(block["columns"]).each do |column|
          found = find_first_body_media(column["children"])
          return found if found
        end
      elsif block["children"].present?
        found = find_first_body_media(block["children"])
        return found if found
      end
    end

    nil
  end
end
