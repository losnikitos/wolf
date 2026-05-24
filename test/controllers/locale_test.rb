require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  test "defaults to russian" do
    get root_url

    assert_response :success
    assert_match(/Клиенты/, response.body)
  end

  test "uses english when lang=en is in the url" do
    get root_url, params: { lang: "en" }

    assert_response :success
    assert_match(/Clients/, response.body)
  end

  test "preserves lang=en in generated links" do
    get root_url, params: { lang: "en" }

    assert_response :success
    assert_match(/lang=en/, response.body)
  end
end
