class Client < ApplicationRecord
  extend FriendlyId

  friendly_id :name, use: :slugged

  NOTION_DATABASE_ID = "0b72b9602a204fb091c165f79234a414".freeze

  has_many :projects, dependent: :nullify

  validates :notion_page_id, presence: true, uniqueness: true

  scope :active, -> { where(archived: false) }
  scope :ordered, -> { order(Arel.sql("client_group IS NULL, client_group ASC"), name: :asc) }

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
