class NotionBodyParser
  TEXT_BLOCK_TYPES = %w[
    paragraph
    heading_1
    heading_2
    heading_3
    bulleted_list_item
    numbered_list_item
    quote
    callout
    toggle
  ].freeze

  MEDIA_BLOCK_TYPES = %w[image video file].freeze

  def self.call(blocks)
    new.call(blocks)
  end

  def call(blocks)
    Array(blocks).filter_map { |block| parse_block(block) }
  end

  private

  def parse_block(block)
    type = block["type"]
    return parse_column_list(block) if type == "column_list"
    return parse_text_block(block) if TEXT_BLOCK_TYPES.include?(type)
    return parse_media_block(block) if MEDIA_BLOCK_TYPES.include?(type)

    nil
  end

  def parse_text_block(block)
    payload = block[block["type"]] || {}
    children = Array(block["children"]).filter_map { |child| parse_block(child) }

    {
      "type" => block["type"],
      "id" => block["id"],
      "rich_text" => normalize_rich_text(payload["rich_text"]),
      "children" => children.presence
    }.compact
  end

  def parse_media_block(block)
    payload = block[block["type"]] || {}
    embed_url = external_url(payload)

    {
      "type" => block["type"],
      "id" => block["id"],
      "caption" => normalize_rich_text(payload["caption"]),
      "embed_url" => embed_url
    }.compact
  end

  def parse_column_list(block)
    columns = Array(block["children"]).map do |column|
      next unless column["type"] == "column"

      {
        "type" => "column",
        "id" => column["id"],
        "children" => Array(column["children"]).filter_map { |child| parse_block(child) }
      }
    end.compact

    return if columns.empty?

    {
      "type" => "column_list",
      "id" => block["id"],
      "column_count" => columns.size,
      "columns" => columns
    }
  end

  def external_url(payload)
    source_type = payload["type"]
    return unless source_type == "external"

    inner = payload["external"]
    inner && inner["url"]
  end

  def normalize_rich_text(rich_text)
    Array(rich_text).filter_map do |segment|
      content = segment["plain_text"].to_s
      next if content.blank?

      {
        "text" => content,
        "href" => segment.dig("text", "link", "url"),
        "bold" => segment.dig("annotations", "bold") == true,
        "italic" => segment.dig("annotations", "italic") == true,
        "underline" => segment.dig("annotations", "underline") == true,
        "strikethrough" => segment.dig("annotations", "strikethrough") == true,
        "code" => segment.dig("annotations", "code") == true
      }.compact
    end
  end
end
