class NotionMediaAppearancesSyncer < Notion::DatabaseSyncer
  configure(
    model: MediaAppearance,
    database_id: MediaAppearance::NOTION_DATABASE_ID,
    title_property: "Name",
    entity_label: "media appearances",
    sync_page_content: true,
    property_map: {
      name: { property: "Name", type: :title },
      topic: { property: "Тема", type: :rich_text },
      location: { property: "Location", type: :rich_text },
      organizer: { property: "Организатор", type: :rich_text },
      appearance_date: { property: "Date", type: :date }
    }
  )

  private

  def assign_relations(media_appearance, page)
    property = page.properties["Проект"]
    page_ids = @property_extractor.extract(property, :relation)
    media_appearance.project = page_ids.present? ? Project.find_by(notion_page_id: page_ids.first) : nil
  end
end
