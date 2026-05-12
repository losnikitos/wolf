namespace :notion do
  desc "Sync the Notion projects database into Project records"
  task sync_projects: :environment do
    result = NotionProjectsSyncer.new.call

    puts "Synced #{result.total} projects (#{result.created} created, #{result.updated} updated, #{result.unchanged} unchanged)."
  end
end
