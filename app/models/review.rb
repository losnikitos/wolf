class Review < ApplicationRecord
  include Embeddable
  include NameSearchable
  include NotionPageContent

  extend FriendlyId

  friendly_id :name, use: :slugged

  NOTION_DATABASE_ID = "399a559fe54b45dabd914a55733f03ba".freeze

  validates :notion_page_id, presence: true, uniqueness: true

  scope :active, -> { where(archived: false) }
  scope :ordered, -> { order(notion_created_at: :desc, name: :asc) }

  def slug_candidates
    [ :name, :notion_page_id ]
  end

  def normalize_friendly_id(value)
    value.to_s.to_slug.transliterate(:russian).normalize.to_s
  end

  def should_generate_new_friendly_id?
    slug.blank? || will_save_change_to_name?
  end

  def embedding_text
    name.to_s
  end
end
