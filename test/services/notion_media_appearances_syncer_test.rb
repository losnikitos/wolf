require "test_helper"
require "ostruct"

class NotionMediaAppearancesSyncerTest < ActiveSupport::TestCase
  setup do
    MediaAppearance.delete_all
    Project.delete_all
    Client.delete_all
  end

  test "creates media appearances from a Notion database" do
    client = FakeNotionClient.new([ notion_page ])

    result = NotionMediaAppearancesSyncer.new(client: client, progress_logger: ->(_) {}).call

    assert_equal 1, result.created
    assert_equal 0, result.updated
    assert_equal 0, result.unchanged
    assert_equal 0, result.skipped

    record = MediaAppearance.find_by!(notion_page_id: "media-page-1")
    assert_equal "Яндекс.Деньги. Как продавать моду миллениалам", record.name
    assert_equal "Модная дискуссия", record.topic
    assert_equal "Лекторий Яндекс.Деньги, Москва", record.location
    assert_equal "Яндекс", record.organizer
    assert_equal Date.new(2017, 12, 7), record.appearance_date
    assert_equal false, record.archived
    assert_not_nil record.last_synced_at
  end

  test "links related projects by Notion page id" do
    project = Project.create!(
      notion_page_id: "project-page-1",
      name: "Sample project"
    )
    client = FakeNotionClient.new([ notion_page(project_relation_id: "project-page-1") ])

    NotionMediaAppearancesSyncer.new(client: client, progress_logger: ->(_) {}).call

    record = MediaAppearance.find_by!(notion_page_id: "media-page-1")
    assert_equal project, record.project
  end

  test "re-syncing unchanged media appearances skips" do
    client = FakeNotionClient.new([ notion_page ])

    NotionMediaAppearancesSyncer.new(client: client, progress_logger: ->(_) {}).call
    first_sync = MediaAppearance.last.last_synced_at

    travel 1.minute do
      result = NotionMediaAppearancesSyncer.new(client: client, progress_logger: ->(_) {}).call
      assert_equal 1, result.skipped
      assert_equal first_sync, MediaAppearance.last.last_synced_at
    end
  end

  private

  def notion_page(last_edited_time: "2018-06-02T12:00:00.000Z", project_relation_id: nil)
    relation = project_relation_id ? [ { "id" => project_relation_id } ] : []

    OpenStruct.new(
      id: "media-page-1",
      url: "https://www.notion.so/media-page-1",
      archived: false,
      created_time: "2018-06-01T12:00:00.000Z",
      last_edited_time: last_edited_time,
      properties: {
        "Name" => { "type" => "title", "title" => [ { "plain_text" => "Яндекс.Деньги. Как продавать моду миллениалам" } ] },
        "Тема" => { "type" => "rich_text", "rich_text" => [ { "plain_text" => "Модная дискуссия" } ] },
        "Location" => { "type" => "rich_text", "rich_text" => [ { "plain_text" => "Лекторий Яндекс.Деньги, Москва" } ] },
        "Организатор" => { "type" => "rich_text", "rich_text" => [ { "plain_text" => "Яндекс" } ] },
        "Date" => { "type" => "date", "date" => { "start" => "2017-12-07" } },
        "Проект" => { "type" => "relation", "relation" => relation }
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
