class Avo::Resources::MediaAppearance < Avo::BaseResource
  self.title = :name
  self.translation_key = "avo.resource_translations.media"
  self.includes = [:project]

  def fields
    field :id, as: :id, hide_on: [:new, :edit]
    field :name, as: :text, required: true, sortable: true
    field :project, as: :belongs_to, searchable: true
    field :publication, as: :text, sortable: true
    field :appearance_date, as: :date, sortable: true
    field :organizer, as: :text, hide_on: [:index]
    field :location, as: :text, hide_on: [:index]
    field :topic, as: :textarea, hide_on: [:index]
    field :url, as: :text, hide_on: [:index]
    field :archived, as: :boolean, sortable: true
    field :slug, as: :text, hide_on: [:index]
    field :body, as: :code, hide_on: [:index]
    field :media, as: :files, hide_on: [:index]
    field :notion_page_id, as: :text, hide_on: [:index]
    field :notion_url, as: :text, hide_on: [:index]
    field :notion_created_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :notion_last_edited_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :last_synced_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :page_content_last_synced_at, as: :date_time, hide_on: [:index, :new, :edit]
  end
end
