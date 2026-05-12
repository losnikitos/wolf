require "test_helper"
require "ostruct"

class NotionProjectsSyncerTest < ActiveSupport::TestCase
  setup do
    Project.delete_all
  end

  test "creates projects from a Notion database" do
    client = FakeNotionClient.new([ notion_page ])

    result = NotionProjectsSyncer.new(client: client).call

    assert_equal 1, result.created
    assert_equal 0, result.updated
    assert_equal 0, result.unchanged

    project = Project.find_by!(notion_page_id: "page-1")
    assert_equal "Открытие магазина", project.name
    assert_equal "Все для видеоигр", project.client
    assert_equal "Успешно выполнен", project.status
    assert_equal "По заказу", project.project_type
    assert_equal "Ижевск", project.city
    assert_equal 2018, project.year
    assert_equal true, project.favorite
    assert_equal false, project.archived
    assert_equal [ "Продюсер" ], project.roles
    assert_equal [ "Мероприятие" ], project.deliverables
    assert_equal [ "Мероприятия" ], project.directions
    assert_equal "https://files.notion/cover.png", project.cover_url
    assert_not_nil project.notion_created_at
    assert_not_nil project.last_synced_at
  end

  test "re-syncing the same data reports unchanged but refreshes last_synced_at" do
    client = FakeNotionClient.new([ notion_page ])
    syncer = NotionProjectsSyncer.new(client: client)

    syncer.call
    first_sync = Project.last.last_synced_at

    travel 1.minute do
      result = syncer.call
      assert_equal 0, result.created
      assert_equal 0, result.updated
      assert_equal 1, result.unchanged
      assert_operator Project.last.last_synced_at, :>, first_sync
    end
  end

  test "detects updates when Notion values change" do
    client = FakeNotionClient.new([ notion_page ])
    NotionProjectsSyncer.new(client: client).call

    updated_client = FakeNotionClient.new([ notion_page(status: "В работе") ])

    result = NotionProjectsSyncer.new(client: updated_client).call

    assert_equal 1, result.updated
    assert_equal "В работе", Project.find_by(notion_page_id: "page-1").status
  end

  test "handles missing properties gracefully" do
    bare = OpenStruct.new(
      id: "page-2",
      url: "https://www.notion.so/page-2",
      archived: false,
      created_time: "2026-05-12T12:00:00.000Z",
      last_edited_time: "2026-05-12T12:00:00.000Z",
      properties: {
        "Проект" => { "type" => "title", "title" => [ { "plain_text" => "Empty" } ] }
      }
    )
    client = FakeNotionClient.new([ bare ])

    NotionProjectsSyncer.new(client: client).call

    project = Project.find_by!(notion_page_id: "page-2")
    assert_equal "Empty", project.name
    assert_nil project.client
    assert_nil project.year
    assert_equal [], project.roles
    assert_equal false, project.favorite
  end

  private

  def notion_page(status: "Успешно выполнен")
    OpenStruct.new(
      id: "page-1",
      url: "https://www.notion.so/page-1",
      archived: false,
      created_time: "2018-06-01T12:00:00.000Z",
      last_edited_time: "2018-06-02T12:00:00.000Z",
      properties: {
        "Проект" => { "type" => "title", "title" => [ { "plain_text" => "Открытие магазина" } ] },
        "Клиент" => { "type" => "select", "select" => { "name" => "Все для видеоигр" } },
        "Статус" => { "type" => "status", "status" => { "name" => status } },
        "Проекты" => { "type" => "select", "select" => { "name" => "По заказу" } },
        "Город" => { "type" => "select", "select" => { "name" => "Ижевск" } },
        "Год" => { "type" => "select", "select" => { "name" => "2018" } },
        "Избранное" => { "type" => "checkbox", "checkbox" => true },
        "Роль" => { "type" => "multi_select", "multi_select" => [ { "name" => "Продюсер" } ] },
        "Результат работ" => { "type" => "multi_select", "multi_select" => [ { "name" => "Мероприятие" } ] },
        "Направление" => { "type" => "multi_select", "multi_select" => [ { "name" => "Мероприятия" } ] },
        "Cover" => {
          "type" => "files",
          "files" => [
            { "name" => "cover.png", "type" => "file", "file" => { "url" => "https://files.notion/cover.png" } }
          ]
        }
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
  end
end
