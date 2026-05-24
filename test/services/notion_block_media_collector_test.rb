require "test_helper"
require "ostruct"

class NotionBlockMediaCollectorTest < ActiveSupport::TestCase
  test "collects image and video blocks recursively" do
    blocks_by_parent = {
      "page-1" => [
        image_block("block-image", "https://files.notion/photo.png"),
        paragraph_block("block-text"),
        toggle_block("block-toggle")
      ],
      "block-toggle" => [
        video_block("block-video", "https://files.notion/clip.mp4")
      ]
    }
    client = FakeNotionClient.new(blocks_by_parent)

    items = NotionBlockMediaCollector.new(client: client).call("page-1")

    assert_equal 2, items.size
    assert_equal(
      [
        { notion_block_id: "block-image", url: "https://files.notion/photo.png", block_type: "image" },
        { notion_block_id: "block-video", url: "https://files.notion/clip.mp4", block_type: "video" }
      ],
      items
    )
  end

  test "deduplicates blocks by notion_block_id" do
    block = image_block("block-image", "https://files.notion/photo.png")
    client = FakeNotionClient.new("page-1" => [ block, block ])

    items = NotionBlockMediaCollector.new(client: client).call("page-1")

    assert_equal 1, items.size
  end

  test "ignores external embed blocks" do
    blocks_by_parent = {
      "page-1" => [
        video_block("block-video", "https://www.youtube.com/watch?v=dQw4w9WgXcQ", external: true)
      ]
    }
    client = FakeNotionClient.new(blocks_by_parent)

    items = NotionBlockMediaCollector.new(client: client).call("page-1")

    assert_empty items
  end

  private

  def image_block(id, url)
    media_block(id, "image", url)
  end

  def video_block(id, url, external: false)
    if external
      {
        "id" => id,
        "type" => "video",
        "has_children" => false,
        "video" => {
          "type" => "external",
          "external" => { "url" => url }
        }
      }
    else
      media_block(id, "video", url)
    end
  end

  def media_block(id, type, url)
    {
      "id" => id,
      "type" => type,
      "has_children" => false,
      type => {
        "type" => "file",
        "file" => { "url" => url }
      }
    }
  end

  def paragraph_block(id)
    {
      "id" => id,
      "type" => "paragraph",
      "has_children" => false,
      "paragraph" => { "rich_text" => [] }
    }
  end

  def toggle_block(id)
    {
      "id" => id,
      "type" => "toggle",
      "has_children" => true,
      "toggle" => { "rich_text" => [] }
    }
  end

  class FakeNotionClient
    def initialize(blocks_by_parent)
      @blocks_by_parent = blocks_by_parent
    end

    def block_children(block_id:, **_options)
      results = @blocks_by_parent[block_id] || []
      yield OpenStruct.new(results: results)
    end
  end
end
