module NotionPageContent
  extend ActiveSupport::Concern

  MEDIA_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
    image/svg+xml
    video/mp4
    video/webm
    video/quicktime
  ].freeze

  included do
    has_many_attached :media
  end

  def media_for_block(notion_block_id)
    media.find { |attachment| attachment.blob.metadata["notion_block_id"] == notion_block_id }
  end

  def page_content_never_synced?
    page_content_last_synced_at.nil?
  end
end
