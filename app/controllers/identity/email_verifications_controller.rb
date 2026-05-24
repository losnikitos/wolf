class Identity::EmailVerificationsController < ApplicationController
  before_action :set_user, only: :show

  def show
    @user.update! verified: true
    redirect_to root_path, notice: t("flash.email_verified")
  end

  def create
    send_email_verification
    redirect_to root_path, notice: t("flash.verification_sent")
  end

  private
    def set_user
      @user = User.find_by_token_for!(:email_verification, params[:sid])
    rescue StandardError
      redirect_to edit_identity_email_path, alert: t("flash.invalid_verification_link")
    end

    def send_email_verification
      UserMailer.with(user: Current.user).email_verification.deliver_later
    end
end
