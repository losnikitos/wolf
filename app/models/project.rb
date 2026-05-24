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

  scope :favorites, -> { where(favorite: true) }
  scope :active, -> { where(archived: false) }

  def slug_candidates
    [ :name, :notion_page_id ]
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end
end
