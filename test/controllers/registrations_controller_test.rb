require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should redirect new when registration is disabled" do
    get sign_up_url
    assert_redirected_to sign_in_url
    assert_equal I18n.t("flash.registration_disabled"), flash[:alert]
  end

  test "should redirect create when registration is disabled" do
    assert_no_difference("User.count") do
      post sign_up_url, params: { email: "lazaronixon@hey.com", password: "Secret1*3*5*", password_confirmation: "Secret1*3*5*" }
    end

    assert_redirected_to sign_in_url
    assert_equal I18n.t("flash.registration_disabled"), flash[:alert]
  end
end
