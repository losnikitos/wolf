require "test_helper"
require "ostruct"

class NotionClientsSyncerTest < ActiveSupport::TestCase
  setup do
    Client.delete_all
  end

  test "creates clients from a Notion database" do
    client = FakeNotionClient.new([ notion_page ])

    result = NotionClientsSyncer.new(client: client, progress_logger: ->(_) {}).call

    assert_equal 1, result.created
    assert_equal 0, result.updated
    assert_equal 0, result.unchanged
    assert_equal 0, result.skipped

    record = Client.find_by!(notion_page_id: "client-page-1")
    assert_equal "Все для видеоигр", record.name
    assert_equal "Развлечения", record.client_group
    assert_equal false, record.archived
    assert_not_nil record.last_synced_at
  end

  test "re-syncing unchanged clients skips" do
    client = FakeNotionClient.new([ notion_page ])

    NotionClientsSyncer.new(client: client, progress_logger: ->(_) {}).call
    first_sync = Client.last.last_synced_at

    travel 1.minute do
      result = NotionClientsSyncer.new(client: client, progress_logger: ->(_) {}).call
      assert_equal 1, result.skipped
      assert_equal first_sync, Client.last.last_synced_at
    end
  end

  private

  def notion_page(last_edited_time: "2018-06-02T12:00:00.000Z")
    OpenStruct.new(
      id: "client-page-1",
      url: "https://www.notion.so/client-page-1",
      archived: false,
      created_time: "2018-06-01T12:00:00.000Z",
      last_edited_time: last_edited_time,
      properties: {
        "Name" => { "type" => "title", "title" => [ { "plain_text" => "Все для видеоигр" } ] },
        "Group" => { "type" => "select", "select" => { "name" => "Развлечения" } }
      }
    )
  end

  class FakeNotionClient
    def initialize(pages)
      @pages = pages
    end

    def database_query(**_options)
      yield OpenStruct.new(results: @pages)
    end

    def page(page_id:)
      @pages.find { |page| page.id == page_id } || raise("Unknown page #{page_id}")
    end
  end
end
