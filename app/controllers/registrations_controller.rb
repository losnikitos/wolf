class RegistrationsController < ApplicationController
  REGISTRATION_ENABLED = false

  before_action :redirect_unless_registration_enabled

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

      send_email_verification
      redirect_to root_path, notice: t("flash.signed_up")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def redirect_unless_registration_enabled
      return if self.class::REGISTRATION_ENABLED

      redirect_to sign_in_path, alert: t("flash.registration_disabled")
    end

    def user_params
      params.permit(:email, :password, :password_confirmation)
    end

    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
