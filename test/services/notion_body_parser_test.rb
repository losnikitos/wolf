require "test_helper"
require "ostruct"

class NotionBodyParserTest < ActiveSupport::TestCase
  test "parses text blocks with rich text annotations" do
    blocks = [
      {
        "id" => "p-1",
        "type" => "paragraph",
        "paragraph" => {
          "rich_text" => [
            {
              "plain_text" => "Hello ",
              "text" => { "content" => "Hello " },
              "annotations" => { "bold" => false, "italic" => false, "underline" => false, "strikethrough" => false, "code" => false }
            },
            {
              "plain_text" => "world",
              "text" => { "content" => "world", "link" => { "url" => "https://example.com" } },
              "annotations" => { "bold" => true, "italic" => false, "underline" => false, "strikethrough" => false, "code" => false }
            }
          ]
        },
        "children" => []
      }
    ]

    body = NotionBodyParser.call(blocks)

    assert_equal 1, body.size
    assert_equal "paragraph", body.first["type"]
    assert_equal 2, body.first["rich_text"].size
    assert_equal "world", body.first["rich_text"].last["text"]
    assert_equal "https://example.com", body.first["rich_text"].last["href"]
    assert_equal true, body.first["rich_text"].last["bold"]
  end

  test "parses image blocks and column layouts" do
    blocks = [
      {
        "id" => "img-1",
        "type" => "image",
        "image" => { "caption" => [] },
        "children" => []
      },
      {
        "id" => "cols-1",
        "type" => "column_list",
        "column_list" => {},
        "children" => [
          {
            "id" => "col-1",
            "type" => "column",
            "column" => {},
            "children" => [
              {
                "id" => "p-left",
                "type" => "paragraph",
                "paragraph" => { "rich_text" => [ { "plain_text" => "Left", "annotations" => {} } ] },
                "children" => []
              }
            ]
          },
          {
            "id" => "col-2",
            "type" => "column",
            "column" => {},
            "children" => [
              {
                "id" => "p-right",
                "type" => "paragraph",
                "paragraph" => { "rich_text" => [ { "plain_text" => "Right", "annotations" => {} } ] },
                "children" => []
              }
            ]
          }
        ]
      }
    ]

    body = NotionBodyParser.call(blocks)

    assert_equal "image", body.first["type"]
    column_list = body.last
    assert_equal "column_list", column_list["type"]
    assert_equal 2, column_list["column_count"]
    assert_equal "Left", column_list["columns"].first["children"].first["rich_text"].first["text"]
  end
end
