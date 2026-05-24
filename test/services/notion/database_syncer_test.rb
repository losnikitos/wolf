require "test_helper"
require "ostruct"

class Notion::DatabaseSyncerTest < ActiveSupport::TestCase
  class TestSyncer < Notion::DatabaseSyncer
    configure(
      model: Client,
      database_id: "test-db",
      title_property: "Name",
      entity_label: "test records",
      property_map: {
        name: { property: "Name", type: :title }
      }
    )
  end

  setup do
    Client.delete_all
  end

  test "creates and updates records through the shared sync loop" do
    page = notion_page
    client = FakeNotionClient.new([ page ])

    result = TestSyncer.new(client: client, progress_logger: ->(_) {}).call

    assert_equal 1, result.created
    record = Client.find_by!(notion_page_id: "test-page-1")
    assert_equal "Sample", record.name
  end

  test "skips unchanged records on re-sync" do
    page = notion_page
    client = FakeNotionClient.new([ page ])
    syncer = TestSyncer.new(client: client, progress_logger: ->(_) {})

    syncer.call
    first_sync = Client.last.last_synced_at

    travel 1.minute do
      result = syncer.call
      assert_equal 1, result.skipped
      assert_equal first_sync, Client.last.last_synced_at
    end
  end

  private

  def notion_page(last_edited_time: "2018-06-02T12:00:00.000Z")
    OpenStruct.new(
      id: "test-page-1",
      url: "https://www.notion.so/test-page-1",
      archived: false,
      created_time: "2018-06-01T12:00:00.000Z",
      last_edited_time: last_edited_time,
      properties: {
        "Name" => { "title" => [ { "plain_text" => "Sample" } ] }
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
