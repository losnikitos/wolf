class Avo::Resources::Client < Avo::BaseResource
  self.title = :name
  self.includes = [:projects]

  def fields
    field :id, as: :id, hide_on: [:new, :edit]
    field :name, as: :text, required: true, sortable: true
    field :client_group, as: :text, sortable: true
    field :slug, as: :text, hide_on: [:index]
    field :archived, as: :boolean, sortable: true
    field :notion_page_id, as: :text, hide_on: [:index]
    field :notion_url, as: :text, hide_on: [:index]
    field :notion_created_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :notion_last_edited_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :last_synced_at, as: :date_time, hide_on: [:index, :new, :edit]
    field :projects, as: :has_many
  end
end
