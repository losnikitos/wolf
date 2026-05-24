require "test_helper"
require "ostruct"

class NotionBlocksFetcherTest < ActiveSupport::TestCase
  test "fetches nested blocks with children" do
    blocks_by_parent = {
      "page-1" => [
        paragraph_block("p-1", "Intro"),
        {
          "id" => "cols-1",
          "type" => "column_list",
          "has_children" => true,
          "column_list" => {}
        }
      ],
      "cols-1" => [
        {
          "id" => "col-1",
          "type" => "column",
          "has_children" => true,
          "column" => {}
        },
        {
          "id" => "col-2",
          "type" => "column",
          "has_children" => true,
          "column" => {}
        }
      ],
      "col-1" => [ paragraph_block("p-2", "Left") ],
      "col-2" => [ paragraph_block("p-3", "Right") ]
    }
    client = FakeNotionClient.new(blocks_by_parent)

    blocks = NotionBlocksFetcher.new(client: client).call("page-1")

    assert_equal 2, blocks.size
    assert_equal "Intro", blocks.first["paragraph"]["rich_text"].first["plain_text"]
    assert_equal 2, blocks.last["children"].size
    assert_equal "Left", blocks.last["children"].first["children"].first["paragraph"]["rich_text"].first["plain_text"]
  end

  private

  def paragraph_block(id, text)
    {
      "id" => id,
      "type" => "paragraph",
      "has_children" => false,
      "paragraph" => { "rich_text" => [ { "plain_text" => text } ] }
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
