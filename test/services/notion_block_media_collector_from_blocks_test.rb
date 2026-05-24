require "test_helper"

class NotionBlockMediaCollectorFromBlocksTest < ActiveSupport::TestCase
  test "collects downloadable media from a normalized block tree" do
    blocks = [
      {
        "id" => "block-image",
        "type" => "image",
        "image" => { "type" => "file", "file" => { "url" => "https://files.notion/photo.png" } },
        "children" => [
          {
            "id" => "block-video",
            "type" => "video",
            "video" => { "type" => "file", "file" => { "url" => "https://files.notion/clip.mp4" } },
            "children" => []
          }
        ]
      },
      {
        "id" => "block-embed",
        "type" => "video",
        "video" => {
          "type" => "external",
          "external" => { "url" => "https://www.youtube.com/watch?v=dQw4w9WgXcQ" }
        },
        "children" => []
      }
    ]

    items = NotionBlockMediaCollector.collect_from_blocks(blocks)

    assert_equal 2, items.size
    assert_equal(
      [
        { notion_block_id: "block-image", url: "https://files.notion/photo.png", block_type: "image" },
        { notion_block_id: "block-video", url: "https://files.notion/clip.mp4", block_type: "video" }
      ],
      items
    )
  end
end
