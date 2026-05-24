module NotionHelper
  def notion_sync_path_for(record)
    notion_sync_path(
      record_type: Notion::RecordSyncer.route_type_for(record),
      slug: record.friendly_id
    )
  end

  def notion_action_icon_class
    "inline-flex items-center justify-center rounded-md p-1.5 text-zinc-400 transition hover:bg-zinc-100 hover:text-zinc-600"
  end
end
