Notion.configure do |config|
  config.token = Rails.application.credentials.notion_api_key
end
