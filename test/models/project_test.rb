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

  test "matching_phrase returns all projects when phrase is blank" do
    create_project!(name: "One")
    create_project!(name: "Two")

    assert_equal 2, Project.matching_phrase("").count
    assert_equal 2, Project.matching_phrase("   ").count
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
