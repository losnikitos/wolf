class Project < ApplicationRecord
  include Embeddable
  include NameSearchable
  include NotionPageContent

  extend FriendlyId

  friendly_id :name, use: :slugged

  belongs_to :client, optional: true
  has_many :media_appearances, dependent: :nullify
  has_many :talks, dependent: :nullify

  NOTION_DATABASE_ID = "16e875f5-4593-80dc-8566-f871610e6bdf".freeze

  COVER_CONTENT_TYPES = NotionPageContent::MEDIA_CONTENT_TYPES

  has_one_attached :cover

  validates :notion_page_id, presence: true, uniqueness: true

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

  def embedding_text
    tags = Array(roles) + Array(deliverables) + Array(directions)
    [ name, *tags ].compact_blank.join(" · ")
  end

  def recommended_projects(limit: 2)
    recommended(limit:)
  end
end
