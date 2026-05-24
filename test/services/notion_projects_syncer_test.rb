require "test_helper"
require "ostruct"

class NotionProjectsSyncerTest < ActiveSupport::TestCase
  setup do
    Project.delete_all
  end

  test "creates projects from a Notion database" do
    client = FakeNotionClient.new([ notion_page ])

    result = with_stubbed_media_sync do |media_attacher, block_collector|
      NotionProjectsSyncer.new(
        client: client,
        media_attacher: media_attacher,
        block_media_collector: block_collector,
        progress_logger: ->(_) {}
      ).call
    end

    assert_equal 1, result.created
    assert_equal 0, result.updated
    assert_equal 0, result.unchanged
    assert_equal 0, result.skipped

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

  test "re-syncing unchanged projects skips and preserves last_synced_at" do
    client = FakeNotionClient.new([ notion_page ])

    with_stubbed_media_sync do |media_attacher, block_collector|
      NotionProjectsSyncer.new(
        client: client,
        media_attacher: media_attacher,
        block_media_collector: block_collector,
        progress_logger: ->(_) {}
      ).call
    end
    project = Project.last
    project.media.attach(
      io: StringIO.new("synced"),
      filename: "placeholder.png",
      content_type: "image/png",
      metadata: { notion_block_id: "block-placeholder", notion_url: "https://files.notion/placeholder.png" }
    )
    first_sync = project.reload.last_synced_at

    travel 1.minute do
      result = with_stubbed_media_sync do |media_attacher, block_collector|
        NotionProjectsSyncer.new(
          client: client,
          media_attacher: media_attacher,
          block_media_collector: block_collector,
          progress_logger: ->(_) {}
        ).call
      end
      assert_equal 0, result.created
      assert_equal 0, result.updated
      assert_equal 0, result.unchanged
      assert_equal 1, result.skipped
      assert_equal first_sync, Project.last.last_synced_at
    end
  end

  test "syncs when notion last_edited_at is newer than last_synced_at" do
    client = FakeNotionClient.new([ notion_page ])
    with_stubbed_media_sync do |media_attacher, block_collector|
      NotionProjectsSyncer.new(
        client: client,
        media_attacher: media_attacher,
        block_media_collector: block_collector,
        progress_logger: ->(_) {}
      ).call
    end

    updated_page = notion_page(last_edited_time: "2026-05-13T12:00:00.000Z")
    updated_client = FakeNotionClient.new([ updated_page ])

    result = with_stubbed_media_sync do |media_attacher, block_collector|
      NotionProjectsSyncer.new(
        client: updated_client,
        media_attacher: media_attacher,
        block_media_collector: block_collector,
        progress_logger: ->(_) {}
      ).call
    end

    assert_equal 1, result.updated
    assert_equal Time.zone.parse("2026-05-13T12:00:00.000Z"), Project.last.notion_last_edited_at
  end

  test "backfills media when project has no attachments despite prior sync" do
    edited_at = Time.zone.parse("2018-06-02T12:00:00.000Z")
    project = Project.create!(
      notion_page_id: "page-1",
      name: "Existing",
      last_synced_at: 1.hour.ago,
      notion_last_edited_at: edited_at
    )
    client = FakeNotionClient.new([ notion_page(last_edited_time: edited_at.iso8601) ])

    media_attacher = TrackingMediaAttacher.new
    block_collector = ->(page_id, client:) { [] }

    result = NotionProjectsSyncer.new(
      client: client,
      media_attacher: media_attacher,
      block_media_collector: block_collector,
      progress_logger: ->(_) {}
    ).call

    assert_equal 0, result.skipped
    assert media_attacher.cover_attached
    assert media_attacher.media_attached
  end

  test "detects updates when Notion values change" do
    client = FakeNotionClient.new([ notion_page ])
    with_stubbed_media_sync do |media_attacher, block_collector|
      NotionProjectsSyncer.new(
        client: client,
        media_attacher: media_attacher,
        block_media_collector: block_collector,
        progress_logger: ->(_) {}
      ).call
    end

    updated_client = FakeNotionClient.new([ notion_page(status: "В работе", last_edited_time: "2026-05-13T12:00:00.000Z") ])

    result = with_stubbed_media_sync do |media_attacher, block_collector|
      NotionProjectsSyncer.new(
        client: updated_client,
        media_attacher: media_attacher,
        block_media_collector: block_collector,
        progress_logger: ->(_) {}
      ).call
    end

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

    with_stubbed_media_sync do |media_attacher, block_collector|
      NotionProjectsSyncer.new(
        client: client,
        media_attacher: media_attacher,
        block_media_collector: block_collector,
        progress_logger: ->(_) {}
      ).call
    end

    project = Project.find_by!(notion_page_id: "page-2")
    assert_equal "Empty", project.name
    assert_nil project.client
    assert_nil project.year
    assert_equal [], project.roles
    assert_equal false, project.favorite
  end

  test "syncs page body from notion blocks" do
    blocks = [
      {
        "id" => "p-1",
        "type" => "paragraph",
        "paragraph" => { "rich_text" => [ { "plain_text" => "Project story", "annotations" => {} } ] },
        "children" => []
      }
    ]
    client = FakeNotionClient.new([ notion_page ], blocks: blocks)

    with_stubbed_media_sync do |media_attacher, block_collector|
      NotionProjectsSyncer.new(
        client: client,
        media_attacher: media_attacher,
        block_media_collector: block_collector,
        progress_logger: ->(_) {}
      ).call
    end

    project = Project.find_by!(notion_page_id: "page-1")
    assert_equal 1, project.body.size
    assert_equal "paragraph", project.body.first["type"]
    assert_equal "Project story", project.body.first["rich_text"].first["text"]
  end

  private

  def with_stubbed_media_sync
    null_attacher = Object.new
    null_attacher.define_singleton_method(:attach_cover!) { |*| }
    null_attacher.define_singleton_method(:attach_media!) { |*, **| }

    null_collector = Object.new
    null_collector.define_singleton_method(:call) { |*, **| [] }

    yield null_attacher, null_collector
  end

  def notion_page(status: "Успешно выполнен", last_edited_time: "2018-06-02T12:00:00.000Z")
    OpenStruct.new(
      id: "page-1",
      url: "https://www.notion.so/page-1",
      archived: false,
      created_time: "2018-06-01T12:00:00.000Z",
      last_edited_time: last_edited_time,
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
    def initialize(pages, blocks: [])
      @pages = pages
      @blocks = blocks
    end

    def database_query(**_options)
      yield OpenStruct.new(results: @pages)
    end

    def block_children(**_options)
      yield OpenStruct.new(results: @blocks)
    end
  end

  class TrackingMediaAttacher
    attr_reader :cover_attached, :media_attached

    def attach_cover!(_project)
      @cover_attached = true
    end

    def attach_media!(_project, _items)
      @media_attached = true
    end
  end
end
