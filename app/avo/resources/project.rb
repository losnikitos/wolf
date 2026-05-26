class Avo::Resources::Project < Avo::BaseResource
  self.title = :name
  self.includes = [:client]

  def fields
    field :id, as: :id, hide_on: [:new, :edit]
    field :name, as: :text, required: true, sortable: true
    field :client, as: :belongs_to, searchable: true
    field :status, as: :text, sortable: true
    field :project_type, as: :text, sortable: true
    field :city, as: :text, sortable: true
    field :year, as: :number, sortable: true
    field :favorite, as: :boolean, sortable: true
    field :archived, as: :boolean, sortable: true
    field :slug, as: :text, hide_on: [:index]
    field :cover, as: :file, hide_on: [:index]
    field :cover_url, as: :text, hide_on: [:index]
    field :roles, as: :tags, hide_on: [:index]
    field :deliverables, as: :tags, hide_on: [:index]
    field :directions, as: :tags, hide_on: [:index]
    field :body, as: :code, hide_on: [:index]
    field :notion_page_id, as: :text, hide_on: [:index]
    field :notion_url, as: :text, hide_on: [:index]
    field :notion_created_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :notion_last_edited_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :last_synced_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :page_content_last_synced_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :media, as: :files, hide_on: [:index]
    field :media_appearances, as: :has_many
    field :talks, as: :has_many
  end
end
