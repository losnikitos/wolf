class Project < ApplicationRecord
  extend FriendlyId

  friendly_id :name, use: :slugged

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

  scope :favorites, -> { where(favorite: true) }
  scope :active, -> { where(archived: false) }

  SEARCHABLE_COLUMNS = %w[name client city project_type status].freeze

  scope :matching_phrase, ->(phrase) {
    phrase = phrase.to_s.strip
    next all if phrase.blank?

    # SQLite only case-folds ASCII (LOWER / COLLATE NOCASE). Match in Ruby so
    # Cyrillic and other scripts are case-insensitive too.
    needle = phrase.downcase
    columns = [ :id, *SEARCHABLE_COLUMNS.map(&:to_sym), :year ]
    matching_ids = unscope(:order).pluck(*columns).filter_map do |row|
      id, *values = row
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
end
