require "test_helper"
require "ostruct"

class NotionReviewsSyncerTest < ActiveSupport::TestCase
  setup do
    Review.delete_all
  end

  test "creates reviews from a Notion database" do
    client = FakeNotionClient.new([ notion_page ])

    result = with_page_content_sync do |page_content_syncer|
      NotionReviewsSyncer.new(
        client: client,
        page_content_syncer: page_content_syncer,
        progress_logger: ->(_) {}
      ).call
    end

    assert_equal 1, result.created
    assert_equal 0, result.updated
    assert_equal 0, result.unchanged
    assert_equal 0, result.skipped

    record = Review.find_by!(notion_page_id: "review-page-1")
    assert_equal "Заварили чат - Волкова", record.name
    assert_equal false, record.archived
    assert_not_nil record.last_synced_at
  end

  test "re-syncing unchanged reviews skips" do
    client = FakeNotionClient.new([ notion_page ])

    with_page_content_sync do |page_content_syncer|
      NotionReviewsSyncer.new(
        client: client,
        page_content_syncer: page_content_syncer,
        progress_logger: ->(_) {}
      ).call
    end
    first_sync = Review.last.last_synced_at

    travel 1.minute do
      result = with_page_content_sync do |page_content_syncer|
        NotionReviewsSyncer.new(
          client: client,
          page_content_syncer: page_content_syncer,
          progress_logger: ->(_) {}
        ).call
      end
      assert_equal 1, result.skipped
      assert_equal first_sync, Review.last.last_synced_at
    end
  end

  private

  def with_page_content_sync(syncer = null_page_content_syncer)
    yield syncer
  end

  def null_page_content_syncer
    syncer = Object.new
    syncer.define_singleton_method(:call) do |record, *, **|
      record.update!(page_content_last_synced_at: Time.current)
    end
    syncer
  end

  def notion_page(last_edited_time: "2026-05-24T19:22:00.000Z")
    OpenStruct.new(
      id: "review-page-1",
      url: "https://www.notion.so/review-page-1",
      archived: false,
      created_time: "2026-05-24T19:22:00.000Z",
      last_edited_time: last_edited_time,
      properties: {
        "Name" => { "type" => "title", "title" => [ { "plain_text" => "Заварили чат - Волкова" } ] }
      }
    )
  end

  class FakeNotionClient
    def initialize(pages, blocks: [])
      @pages = pages
      @blocks = blocks
    end

    def database_query(**_options)
      yield OpenStruct.new(results: @pages)
    end

    def page(page_id:)
      @pages.find { |page| page.id == page_id } || raise("Unknown page #{page_id}")
    end

    def block_children(**_options)
      yield OpenStruct.new(results: @blocks)
    end
  end
end
