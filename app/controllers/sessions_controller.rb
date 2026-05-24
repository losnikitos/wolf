class SessionsController < ApplicationController
  before_action :set_session, only: :destroy

  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
  end

  def new
  end

  def create
    if user = User.authenticate_by(email: params[:email], password: params[:password])
      @session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }

      redirect_to root_path, notice: t("flash.signed_in")
    else
      redirect_to sign_in_path(email_hint: params[:email]), alert: t("flash.invalid_credentials")
    end
  end

  def destroy
    @session.destroy; redirect_to(sessions_path, notice: t("flash.session_logged_out"))
  end

  def sign_out
    Current.session&.destroy

    redirect_to root_path, notice: t("flash.signed_out")
  end

  private
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
