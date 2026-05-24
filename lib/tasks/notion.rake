namespace :notion do
  desc "Sync the Notion clients database into Client records"
  task sync_clients: :environment do
    result = NotionClientsSyncer.new.call

    puts "Synced #{result.total} clients (#{result.created} created, #{result.updated} updated, #{result.unchanged} unchanged, #{result.skipped} skipped)."
  end

  desc "Sync the Notion media appearances database into MediaAppearance records"
  task sync_media: :environment do
    force = ENV["FORCE"] == "1"
    result = NotionMediaAppearancesSyncer.new(force: force).call

    puts "Synced #{result.total} media appearances (#{result.created} created, #{result.updated} updated, #{result.unchanged} unchanged, #{result.skipped} skipped)."
  end

  desc "Sync the Notion public talks database into Talk records"
  task sync_talks: :environment do
    force = ENV["FORCE"] == "1"
    result = NotionTalksSyncer.new(force: force).call

    removed = result.removed_from_media
    removed_message = removed.positive? ? ", #{removed} removed from media" : ""
    puts "Synced #{result.total} talks (#{result.created} created, #{result.updated} updated, #{result.unchanged} unchanged, #{result.skipped} skipped#{removed_message})."
  end

  desc "Sync clients, projects, media, and talks from Notion"
  task sync: %i[sync_clients sync_projects sync_media sync_talks]

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

  desc "Force-sync one Notion talk by page ID (ignores last-edited cache)"
  task :sync_talk, [ :notion_page_id ] => :environment do |_task, args|
    notion_page_id = args[:notion_page_id].presence || ENV["NOTION_PAGE_ID"]
    abort "Usage: bin/rails 'notion:sync_talk[NOTION_PAGE_ID]' (or NOTION_PAGE_ID=... bin/rails notion:sync_talk)" unless notion_page_id

    result = NotionTalksSyncer.new(force: true).call(notion_page_id: notion_page_id)

    puts "Synced 1 talk (#{result.created} created, #{result.updated} updated, #{result.unchanged} unchanged, #{result.skipped} skipped)."
  end

  desc "Force-sync one Notion media appearance by page ID (ignores last-edited cache)"
  task :sync_media_page, [ :notion_page_id ] => :environment do |_task, args|
    notion_page_id = args[:notion_page_id].presence || ENV["NOTION_PAGE_ID"]
    abort "Usage: bin/rails 'notion:sync_media_page[NOTION_PAGE_ID]' (or NOTION_PAGE_ID=... bin/rails notion:sync_media_page)" unless notion_page_id

    result = NotionMediaAppearancesSyncer.new(force: true).call(notion_page_id: notion_page_id)

    puts "Synced 1 media appearance (#{result.created} created, #{result.updated} updated, #{result.unchanged} unchanged, #{result.skipped} skipped)."
  end
end
