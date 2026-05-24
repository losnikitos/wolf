class Project < ApplicationRecord
  extend FriendlyId

  friendly_id :name, use: :slugged

  belongs_to :client, optional: true

  NOTION_DATABASE_ID = "16e875f5-4593-80dc-8566-f871610e6bdf".freeze

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

  COVER_CONTENT_TYPES = MEDIA_CONTENT_TYPES

  has_one_attached :cover
  has_many_attached :media

  validates :notion_page_id, presence: true, uniqueness: true

  def media_for_block(notion_block_id)
    media.find { |attachment| attachment.blob.metadata["notion_block_id"] == notion_block_id }
  end

  def cover_for_display
    return cover if cover.attached?
    return if cover_url.present?

    first_body_media
  end

  def cover_for_display?
    cover.attached? || cover_url.present? || first_body_media.present?
  end

  def first_body_media
    find_first_body_media(body)
  end

  TAG_KINDS = %w[roles deliverables directions].freeze

  scope :favorites, -> { where(favorite: true) }
  scope :active, -> { where(archived: false) }

  scope :with_tag, ->(kind, value) {
    kind = kind.to_s
    raise ArgumentError, "unknown tag kind: #{kind}" unless TAG_KINDS.include?(kind)

    value = value.to_s
    where(
      "EXISTS (SELECT 1 FROM json_each(#{table_name}.#{kind}) WHERE value = ?)",
      value
    )
  }

  SEARCHABLE_COLUMNS = %w[name city project_type status].freeze

  scope :matching_phrase, ->(phrase) {
    phrase = phrase.to_s.strip
    next all if phrase.blank?

    # SQLite only case-folds ASCII (LOWER / COLLATE NOCASE). Match in Ruby so
    # Cyrillic and other scripts are case-insensitive too.
    needle = phrase.downcase
    rows = unscope(:order).left_joins(:client).pluck(
      :id,
      :name,
      :city,
      :project_type,
      :status,
      :year,
      "clients.name"
    )
    matching_ids = rows.filter_map do |id, *values|
      id if values.any? { |value| value.to_s.downcase.include?(needle) }
    end

    where(id: matching_ids)
  }

  def slug_candidates
    [ :name, :notion_page_id ]
  end

  def normalize_friendly_id(value)
    value.to_s.to_slug.transliterate(:russian).normalize.to_s
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end

  private

  BODY_MEDIA_BLOCK_TYPES = NotionBodyParser::MEDIA_BLOCK_TYPES

  def find_first_body_media(blocks)
    Array(blocks).each do |block|
      type = block["type"]

      if BODY_MEDIA_BLOCK_TYPES.include?(type)
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
