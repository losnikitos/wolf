class NotionReviewsSyncer < Notion::DatabaseSyncer
  configure(
    model: Review,
    database_id: Review::NOTION_DATABASE_ID,
    title_property: "Name",
    entity_label: "reviews",
    sync_page_content: true,
    property_map: {
      name: { property: "Name", type: :title }
    }
  )
end
