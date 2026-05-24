class Project < ApplicationRecord
  NOTION_DATABASE_ID = "16e875f5-4593-80dc-8566-f871610e6bdf".freeze

  COVER_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
    image/svg+xml
    video/mp4
    video/webm
    video/quicktime
  ].freeze

  has_one_attached :cover

  validates :notion_page_id, presence: true, uniqueness: true

  scope :favorites, -> { where(favorite: true) }
  scope :active, -> { where(archived: false) }
end
