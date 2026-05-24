namespace :notion do
  desc "Sync the Notion projects database into Project records"
  task sync_projects: :environment do
    result = NotionProjectsSyncer.new.call

    puts "Synced #{result.total} projects (#{result.created} created, #{result.updated} updated, #{result.unchanged} unchanged, #{result.skipped} skipped)."
  end

  desc "Force-sync one Notion project by page ID (ignores last-edited cache)"
  task :sync_project, [ :notion_page_id ] => :environment do |_task, args|
    notion_page_id = args[:notion_page_id].presence || ENV["NOTION_PAGE_ID"]
    abort "Usage: bin/rails 'notion:sync_project[NOTION_PAGE_ID]' (or NOTION_PAGE_ID=... bin/rails notion:sync_project)" unless notion_page_id

    result = NotionProjectsSyncer.new(force: true).call(notion_page_id: notion_page_id)

    puts "Synced 1 project (#{result.created} created, #{result.updated} updated, #{result.unchanged} unchanged)."
  end
end
