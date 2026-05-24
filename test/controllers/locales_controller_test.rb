require "test_helper"

class LocalesControllerTest < ActionDispatch::IntegrationTest
  test "update stores locale in session and redirects back" do
    patch locale_url, params: { locale: "en" }, headers: { "HTTP_REFERER" => root_url }

    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Clients/, response.body)
  end

  test "update ignores invalid locale" do
    patch locale_url, params: { locale: "fr" }, headers: { "HTTP_REFERER" => root_url }

    assert_redirected_to root_url
    follow_redirect!
    assert_match(/Клиенты/, response.body)
  end

  test "prefers English from Accept-Language when session is unset" do
    get root_url, headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9" }

    assert_response :success
    assert_match(/Clients/, response.body)
  end

  test "prefers Russian from Accept-Language when session is unset" do
    get root_url, headers: { "HTTP_ACCEPT_LANGUAGE" => "ru-RU,ru;q=0.9,en;q=0.8" }

    assert_response :success
    assert_match(/Клиенты/, response.body)
  end

  test "session locale overrides Accept-Language" do
    patch locale_url, params: { locale: "en" }, headers: { "HTTP_REFERER" => root_url }
    follow_redirect!

    get root_url, headers: { "HTTP_ACCEPT_LANGUAGE" => "ru-RU,ru;q=0.9" }

    assert_match(/Clients/, response.body)
  end
end
