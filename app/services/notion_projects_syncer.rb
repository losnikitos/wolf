class NotionProjectsSyncer < Notion::DatabaseSyncer
  configure(
    model: Project,
    database_id: Project::NOTION_DATABASE_ID,
    title_property: "Проект",
    entity_label: "projects",
    sync_page_content: true,
    property_map: {
      name: { property: "Проект", type: :title },
      status: { property: "Статус", type: :status },
      project_type: { property: "Проекты", type: :select },
      city: { property: "Город", type: :select },
      year: { property: "Год", type: :year },
      cover_url: { property: "Cover", type: :first_file_url },
      favorite: { property: "Избранное", type: :checkbox },
      roles: { property: "Роль", type: :multi_select },
      deliverables: { property: "Результат работ", type: :multi_select },
      directions: { property: "Направление", type: :multi_select }
    }
  )

  private

  def upsert(record, page)
    outcome = super
    ProjectEmbeddingJob.perform_later(record) if %i[created updated].include?(outcome)
    outcome
  end

  def assign_relations(project, page)
    property = page.properties["Client"]
    page_ids = @property_extractor.extract(property, :relation)
    project.client = page_ids.present? ? Client.find_by(notion_page_id: page_ids.first) : nil
  end
end
