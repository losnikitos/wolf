require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Project.delete_all
    Client.delete_all
    BlogPost.delete_all
  end

  test "show returns xml sitemap with active project urls" do
    project = create_project!(name: "Visible Project", archived: false)
    create_project!(name: "Hidden Project", archived: true)

    get "/sitemap.xml"

    assert_response :success
    assert_includes response.media_type, "xml"
    assert_includes response.body, project_url(project)
    assert_not_includes response.body, "hidden-project"
    assert_not_includes response.body, "/search"
    assert_not_includes response.body, "/sign_in"
    assert_not_includes response.body, "/avo/"
  end

  test "show includes static index pages" do
    get "/sitemap.xml"

    assert_response :success
    assert_includes response.body, root_url
    assert_includes response.body, projects_url
    assert_includes response.body, clients_url
    assert_includes response.body, media_url
    assert_includes response.body, blog_index_url
  end

  test "show includes project collection pages for active tags" do
    create_project!(
      name: "Tagged Project",
      roles: [ "Branding" ],
      archived: false
    )

    get "/sitemap.xml"

    assert_response :success
    assert_includes response.body, collection_projects_url(kind: "roles", tag: "Branding")
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
