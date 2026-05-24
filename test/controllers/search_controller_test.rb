require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    Client.delete_all
    Project.delete_all
    MediaAppearance.delete_all
    Talk.delete_all
  end

  test "index renders search page" do
    get search_url
    assert_response :success
    assert_select "h1", "Search"
  end

  test "index searches active records by name across entity types" do
    client = Client.create!(notion_page_id: SecureRandom.uuid, name: "Alpha Client")
    create_project!(name: "Alpha Project", client: client)
    MediaAppearance.create!(notion_page_id: SecureRandom.uuid, name: "Alpha Media")
    Talk.create!(notion_page_id: SecureRandom.uuid, name: "Alpha Talk")
    Client.create!(notion_page_id: SecureRandom.uuid, name: "Beta Client", archived: true)

    get search_url, params: { q: "alpha" }
    assert_response :success
    assert_includes response.body, "Alpha Project"
    assert_includes response.body, "Alpha Client"
    assert_includes response.body, "Alpha Media"
    assert_includes response.body, "Alpha Talk"
    assert_not_includes response.body, "Beta Client"
  end

  test "index shows empty state when there are no matches" do
    create_project!(name: "Only Project")

    get search_url, params: { q: "missing" }
    assert_response :success
    assert_match(/No matches/, response.body)
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
