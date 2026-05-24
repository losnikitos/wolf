class NotionPageContentSyncer
  def self.call(record, page_id, client: nil, **dependencies)
    new(record, page_id, client: client, **dependencies).call
  end

  def initialize(
    record,
    page_id,
    client: nil,
    blocks_fetcher: NotionBlocksFetcher,
    body_parser: NotionBodyParser,
    block_media_collector: NotionBlockMediaCollector,
    media_attacher: NotionMediaAttacher
  )
    @record = record
    @page_id = page_id
    @client = client || Notion::Client.new
    @blocks_fetcher = blocks_fetcher
    @body_parser = body_parser
    @block_media_collector = block_media_collector
    @media_attacher = media_attacher
  end

  def call
    sync_cover! if cover_syncable?
    sync_body_and_media!
  end

  private

  def cover_syncable?
    @record.respond_to?(:cover_url) && @record.respond_to?(:cover)
  end

  def sync_cover!
    @media_attacher.attach_cover!(@record)
  end

  def sync_body_and_media!
    items = @block_media_collector.call(@page_id, client: @client)
    @media_attacher.attach_media!(@record, items)
    blocks = @blocks_fetcher.call(@page_id, client: @client)
    @record.update!(
      body: @body_parser.call(blocks),
      page_content_last_synced_at: Time.current
    )
  end
end
