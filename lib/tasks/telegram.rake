namespace :telegram do
  desc "Import blog posts from telegram/volkdays_export.json"
  task import: :environment do
    ImportTelegramExportJob.perform_now
  end
end
