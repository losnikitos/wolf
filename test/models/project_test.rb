require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    Project.delete_all
  end

  test "matching_phrase is case insensitive and matches exact substring" do
    acme = Client.create!(notion_page_id: SecureRandom.uuid, name: "Acme Corp")
    other = Client.create!(notion_page_id: SecureRandom.uuid, name: "Other LLC")
    create_project!(name: "Alpha Store", client: acme, city: "Moscow")
    create_project!(name: "Beta Launch", client: other, city: "Berlin")

    assert_equal 1, Project.matching_phrase("alpha").count
    assert_equal 1, Project.matching_phrase("ALPHA").count
    assert_equal 1, Project.matching_phrase("acme corp").count
    assert_equal 0, Project.matching_phrase("alpha beta").count
  end

  test "matching_phrase matches cyrillic substring" do
    create_project!(name: "Вторая версия онлайн-сервиса TADAAA!")

    assert_equal 1, Project.matching_phrase("Вторая").count
    assert_equal 1, Project.matching_phrase("вторая").count
    assert_equal 1, Project.matching_phrase("онлайн").count
    assert_equal 0, Project.matching_phrase("несуществующий").count
  end

  test "matching_phrase returns all projects when phrase is blank" do
    create_project!(name: "One")
    create_project!(name: "Two")

    assert_equal 2, Project.matching_phrase("").count
    assert_equal 2, Project.matching_phrase("   ").count
  end

  test "with_tag filters by json tag column" do
    create_project!(name: "Room", deliverables: [ "Помещение" ], roles: [ "Продюсер" ])
    create_project!(name: "Event", deliverables: [ "Мероприятие" ])
    create_project!(name: "Archived room", deliverables: [ "Помещение" ], archived: true)

    assert_equal [ "Archived room", "Room" ], Project.with_tag(:deliverables, "Помещение").order(:name).pluck(:name)
    assert_equal [ "Archived room", "Room" ], Project.with_tag("deliverables", "Помещение").order(:name).pluck(:name)
    assert_equal [ "Room" ], Project.active.with_tag(:deliverables, "Помещение").pluck(:name)
    assert_equal [ "Room" ], Project.with_tag(:roles, "Продюсер").pluck(:name)
    assert_empty Project.with_tag(:deliverables, "Несуществующий")
  end

  test "with_tag raises for unknown kind" do
    assert_raises(ArgumentError) { Project.with_tag(:unknown, "x") }
  end

  test "cover_for_display uses attached cover when present" do
    project = create_project!(name: "With cover")
    project.cover.attach(
      io: StringIO.new("cover"),
      filename: "cover.png",
      content_type: "image/png"
    )
    project.media.attach(
      io: StringIO.new("body"),
      filename: "body.png",
      content_type: "image/png",
      metadata: { notion_block_id: "block-1" }
    )
    project.update!(body: [ { "type" => "image", "id" => "block-1" } ])

    assert_equal project.cover, project.cover_for_display
  end

  test "cover_for_display falls back to first body media in document order" do
    project = create_project!(name: "Body only")
    project.media.attach(
      io: StringIO.new("first"),
      filename: "first.png",
      content_type: "image/png",
      metadata: { notion_block_id: "block-1" }
    )
    project.media.attach(
      io: StringIO.new("second"),
      filename: "second.png",
      content_type: "image/png",
      metadata: { notion_block_id: "block-2" }
    )
    project.update!(
      body: [
        { "type" => "paragraph", "id" => "intro", "rich_text" => [ { "text" => "Hello" } ] },
        { "type" => "image", "id" => "block-1" },
        { "type" => "image", "id" => "block-2" }
      ]
    )

    assert_equal "block-1", project.cover_for_display.blob.metadata["notion_block_id"]
  end

  test "cover_for_display walks nested body blocks and columns" do
    project = create_project!(name: "Nested")
    project.media.attach(
      io: StringIO.new("nested"),
      filename: "nested.png",
      content_type: "image/png",
      metadata: { notion_block_id: "nested-block" }
    )
    project.update!(
      body: [
        {
          "type" => "column_list",
          "id" => "cols",
          "columns" => [
            {
              "type" => "column",
              "id" => "col-1",
              "children" => [
                { "type" => "paragraph", "id" => "p1", "rich_text" => [ { "text" => "Left" } ] }
              ]
            },
            {
              "type" => "column",
              "id" => "col-2",
              "children" => [
                { "type" => "image", "id" => "nested-block" }
              ]
            }
          ]
        }
      ]
    )

    assert_equal "nested-block", project.cover_for_display.blob.metadata["notion_block_id"]
  end

  test "cover_for_display does not use cover_url when cover not attached" do
    project = create_project!(name: "URL cover", cover_url: "https://example.com/cover.jpg")
    project.media.attach(
      io: StringIO.new("body"),
      filename: "body.png",
      content_type: "image/png",
      metadata: { notion_block_id: "block-1" }
    )
    project.update!(body: [ { "type" => "image", "id" => "block-1" } ])

    assert_equal "block-1", project.cover_for_display.blob.metadata["notion_block_id"]
    assert project.cover_for_display?
    assert_nil project.notion_cover_for_display
    assert project.notion_cover_for_display?
  end

  test "notion_cover_for_display does not fall back to body media" do
    project = create_project!(name: "Body only")
    project.media.attach(
      io: StringIO.new("first"),
      filename: "first.png",
      content_type: "image/png",
      metadata: { notion_block_id: "block-1" }
    )
    project.update!(body: [ { "type" => "image", "id" => "block-1" } ])

    assert_nil project.notion_cover_for_display
    assert_not project.notion_cover_for_display?
    assert_equal "block-1", project.cover_for_display.blob.metadata["notion_block_id"]
    assert project.cover_for_display?
  end

  private

  def create_project!(**attrs)
    Project.create!(
      {
        notion_page_id: SecureRandom.uuid,
        name: "Project",
        archived: false
      }.merge(attrs)
    )
  end
end
