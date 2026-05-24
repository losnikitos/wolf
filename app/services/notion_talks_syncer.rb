class NotionTalksSyncer < Notion::DatabaseSyncer
  configure(
    model: Talk,
    database_id: Talk::NOTION_DATABASE_ID,
    title_property: "Name",
    entity_label: "talks",
    sync_page_content: true,
    property_map: {
      name: { property: "Name", type: :title },
      topic: { property: "Тема", type: :rich_text },
      location: { property: "Location", type: :rich_text },
      organizer: { property: "Организатор", type: :rich_text },
      talk_date: { property: "Date", type: :date }
    }
  )

  private

  def assign_relations(talk, page)
    property = page.properties["Проект"]
    page_ids = @property_extractor.extract(property, :relation)
    talk.project = page_ids.present? ? Project.find_by(notion_page_id: page_ids.first) : nil
  end

  def after_full_sync(notion_page_id:)
    removed_from_media = notion_page_id ? 0 : cleanup_misplaced_media!
    { removed_from_media: removed_from_media }
  end

  def cleanup_misplaced_media!
    MediaAppearance.where(notion_page_id: Talk.select(:notion_page_id)).destroy_all.size
  end
end
