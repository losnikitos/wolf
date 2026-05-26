require "test_helper"

class AvoAuthenticationTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to sign in" do
    get "/avo"

    assert_response :redirect
    assert_equal "/sign_in", URI.parse(response.redirect_url).path
  end

  test "allows authenticated users" do
    sign_in_as users(:lazaro_nixon)

    get "/avo"

    assert_response :redirect
    assert_redirected_to "/avo/resources/clients"
  end
end
