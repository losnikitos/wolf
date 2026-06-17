class BlogPost < ApplicationRecord
  extend FriendlyId

  friendly_id :title, use: :slugged

  has_many_attached :media

  validates :telegram_message_id, presence: true, uniqueness: true
  validates :published_at, presence: true

  scope :active, -> { where(archived: false) }
  scope :ordered, -> { order(published_at: :desc) }

  def slug_candidates
    [ :title, :telegram_message_id ]
  end

  def normalize_friendly_id(value)
    value.to_s.to_slug.transliterate(:russian).normalize.to_s
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_title?
  end

  def published_year
    published_at&.year
  end

  def telegram_url
    "https://t.me/volkdays/#{telegram_message_id}"
  end

  def excerpt
    body.to_s.squish.truncate(160)
  end

  def ordered_media
    media_attachments.sort_by { |attachment| attachment.blob.metadata.fetch("position", 0) }
  end

  def cover_attachment
    ordered_media.find { |attachment| attachment.blob.image? }
  end

  def cover_for_display?
    cover_attachment.present?
  end

  def name
    title
  end
end
