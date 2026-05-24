class NotionClientsSyncer < Notion::DatabaseSyncer
  configure(
    model: Client,
    database_id: Client::NOTION_DATABASE_ID,
    title_property: "Name",
    entity_label: "clients",
    property_map: {
      name: { property: "Name", type: :title },
      client_group: { property: "Group", type: :select }
    }
  )
end
