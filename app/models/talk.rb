class Talk < ApplicationRecord
  include NotionPageContent

  extend FriendlyId

  friendly_id :name, use: :slugged

  belongs_to :project, optional: true

  NOTION_DATABASE_ID = "16f875f54593806fabfed0a650d795a9".freeze

  validates :notion_page_id, presence: true, uniqueness: true

  scope :active, -> { where(archived: false) }
  scope :ordered, -> { order(talk_date: :desc, name: :asc) }

  def slug_candidates
    [ :name, :notion_page_id ]
  end

  def normalize_friendly_id(value)
    value.to_s.to_slug.transliterate(:russian).normalize.to_s
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end

  def talk_year
    talk_date&.year
  end
end
