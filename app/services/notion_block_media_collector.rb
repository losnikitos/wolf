class NotionBlockMediaCollector
  MEDIA_BLOCK_TYPES = %w[image video file].freeze

  def self.call(page_id, client: nil)
    new(client: client).call(page_id)
  end

  def initialize(client: nil)
    @client = client || Notion::Client.new
  end

  def call(page_id)
    items = []
    collect_blocks(page_id, items)
    items.uniq { |item| item[:notion_block_id] }
  end

  private

  def collect_blocks(block_id, items)
    @client.block_children(block_id: block_id, page_size: 100) do |response|
      response.results.each do |block|
        extract_media(block, items)
        collect_blocks(block_id_for(block), items) if block_attr(block, "has_children")
      end
    end
  end

  def extract_media(block, items)
    block_type = block_attr(block, "type")
    return unless MEDIA_BLOCK_TYPES.include?(block_type)

    payload = block_attr(block, block_type)
    return unless payload

    url = file_url(payload)
    return if url.blank?

    items << {
      notion_block_id: block_id_for(block),
      url: url,
      block_type: block_type
    }
  end

  def file_url(payload)
    source_type = payload["type"] || payload[:type]
    return unless source_type == "file"

    inner = payload[source_type] || payload[source_type.to_sym]
    inner && (inner["url"] || inner[:url])
  end

  def block_id_for(block)
    block_attr(block, "id")
  end

  def block_attr(block, key)
    if block.respond_to?(:[])
      value = block[key]
      return value unless value.nil?
    end

    block.public_send(key) if block.respond_to?(key)
  end
end
