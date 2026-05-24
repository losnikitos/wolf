require "test_helper"

class NotionSyncsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:lazaro_nixon)
    @project = Project.create!(notion_page_id: "page-sync-1", name: "Sync Test Project")
  end

  test "requires authentication" do
    post notion_sync_path(record_type: "projects", slug: @project.slug)

    assert_redirected_to sign_in_path
  end

  test "returns not found for missing record" do
    sign_in_as @user

    post notion_sync_path(record_type: "projects", slug: "missing-slug"),
      headers: { "HTTP_REFERER" => root_url }

    assert_response :not_found
  end
end
