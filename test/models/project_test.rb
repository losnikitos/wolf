require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    Project.delete_all
  end

  test "matching_phrase is case insensitive and matches exact substring" do
    create_project!(name: "Alpha Store", client: "Acme Corp", city: "Moscow")
    create_project!(name: "Beta Launch", client: "Other LLC", city: "Berlin")

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
