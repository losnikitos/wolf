require "test_helper"

class NameSearchableTest < ActiveSupport::TestCase
  setup do
    Client.delete_all
    Project.delete_all
  end

  test "matching_name is case insensitive and matches substring in name only" do
    client = Client.create!(notion_page_id: SecureRandom.uuid, name: "Acme Corp")
    create_project!(name: "Alpha Store", client: client, city: "Moscow")
    create_project!(name: "Beta Launch", city: nil)

    assert_equal 1, Project.matching_name("alpha").count
    assert_equal 1, Project.matching_name("ALPHA").count
    assert_equal 0, Project.matching_name("acme").count
    assert_equal 0, Project.matching_name("moscow").count
  end

  test "matching_name matches cyrillic names" do
    create_project!(name: "Вторая версия онлайн-сервиса")

    assert_equal 1, Project.matching_name("Вторая").count
    assert_equal 1, Project.matching_name("вторая").count
    assert_equal 0, Project.matching_name("несуществующий").count
  end

  test "matching_name returns all records when phrase is blank" do
    create_project!(name: "One")
    create_project!(name: "Two")

    assert_equal 2, Project.matching_name("").count
    assert_equal 2, Project.matching_name("   ").count
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
