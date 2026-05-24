require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  test "defaults to russian" do
    get root_url

    assert_response :success
    assert_match(/Клиенты/, response.body)
  end

  test "uses english when locale is stored in session" do
    patch locale_url, params: { locale: "en" }, headers: { "HTTP_REFERER" => root_url }
    follow_redirect!

    assert_match(/Clients/, response.body)
  end

  test "generated links do not include lang query param" do
    patch locale_url, params: { locale: "en" }, headers: { "HTTP_REFERER" => root_url }
    follow_redirect!

    assert_response :success
    assert_no_match(/\?lang=/, response.body)
  end
end
