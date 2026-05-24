class NotionBlocksFetcher
  def self.call(block_id, client: nil)
    new(client: client).call(block_id)
  end

  def initialize(client: nil)
    @client = client || Notion::Client.new
  end

  def call(block_id)
    fetch_children(block_id)
  end

  private

  def fetch_children(block_id)
    @client.block_children(block_id: block_id, page_size: 100) do |response|
      response.results.map { |block| normalize(block) }
    end
  rescue StandardError
    []
  end

  def normalize(block)
    type = block_attr(block, "type")
    payload = block_attr(block, type)
    children = block_attr(block, "has_children") ? fetch_children(block_id_for(block)) : []

    {
      "id" => block_id_for(block),
      "type" => type,
      type => payload,
      "children" => children
    }
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
