class LocalesController < ApplicationController
  def update
    locale = params[:locale].to_s
    session[:locale] = locale if I18n.available_locales.map(&:to_s).include?(locale)

    redirect_back fallback_location: root_path, allow_other_host: false
  end
end
