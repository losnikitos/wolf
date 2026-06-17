require "test_helper"
require "ostruct"

class SeoHelperTest < ActionView::TestCase
  include SeoHelper
  include ApplicationHelper

  setup do
    @controller = HomeController.new
    @request = ActionDispatch::TestRequest.create
    @controller.request = @request
    @controller.response = ActionDispatch::TestResponse.new
  end

  test "seo_title formats branded title" do
    I18n.with_locale(:en) do
      assert_equal "Alpha | Eugene Wolf", seo_title("Alpha")
    end
  end

  test "seo_title uses home format for site name" do
    I18n.with_locale(:en) do
      assert_equal "Eugene Wolf — Client service, naming, production", seo_title(t("site.name"))
    end
  end

  test "seo_description truncates long text" do
    text = "a" * 200
    assert_equal 160, seo_description(text).length
  end

  test "notion_body_excerpt extracts first paragraph" do
    record = OpenStruct.new(
      body: [
        {
          "type" => "paragraph",
          "rich_text" => [ { "text" => "First paragraph text." } ]
        }
      ]
    )

    assert_equal "First paragraph text.", notion_body_excerpt(record)
  end

  test "record_seo_description falls back to name" do
    client = Client.new(name: "Acme Corp")

    assert_equal "Acme Corp", record_seo_description(client)
  end

  test "seo_noindex is false for home" do
    assert_not seo_noindex?
  end

  test "seo_noindex is true for search" do
    @controller = SearchController.new
    @controller.request = @request

    assert seo_noindex?
  end

  test "seo_noindex is true for identity controllers" do
    @controller = Identity::EmailsController.new
    @controller.request = @request

    assert seo_noindex?
  end

  test "seo_canonical_url strips query string" do
    @request.env["HTTPS"] = "on"
    @request.host = "example.com"
    @request.path = "/search"
    @request.env["QUERY_STRING"] = "q=alpha"
    @request.env["REQUEST_URI"] = "/search?q=alpha"

    assert_equal "https://example.com/search", seo_canonical_url
  end
end
