# Notion cover files are images or short videos served inline in the browser.
Rails.application.config.active_storage.content_types_allowed_inline += %w[
  video/mp4
  video/webm
  video/quicktime
]
