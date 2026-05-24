class NotionMediaAppearancesSyncer < Notion::DatabaseSyncer
  configure(
    model: MediaAppearance,
    database_id: MediaAppearance::NOTION_DATABASE_ID,
    title_property: "Name",
    entity_label: "media appearances",
    sync_page_content: true,
    property_map: {
      name: { property: "Name", type: :title },
      appearance_date: { property: "Publication Date", type: :date },
      url: { property: "URL", type: :url },
      publication: { property: "Издание", type: :select }
    }
  )
end
