class ImportTelegramExportJob < ApplicationJob
  queue_as :default

  def perform(json_path: nil, attachments_root: nil)
    TelegramExportImporter.new(
      json_path: json_path || TelegramExportImporter::DEFAULT_JSON_PATH,
      attachments_root: attachments_root || TelegramExportImporter::DEFAULT_ATTACHMENTS_ROOT
    ).call
  end
end
