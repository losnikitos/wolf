class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :set_current_request_details
  before_action :authenticate

  private
    def set_locale
      I18n.locale = resolve_locale
    end

    def resolve_locale
      session_locale || browser_preferred_locale || I18n.default_locale
    end

    def session_locale
      locale = session[:locale]&.to_sym
      locale if I18n.available_locales.include?(locale)
    end

    def browser_preferred_locale
      header = request.env["HTTP_ACCEPT_LANGUAGE"]
      return unless header.present?

      header.split(",").filter_map do |part|
        lang_tag, quality = part.strip.split(";")
        quality = quality&.match(/q=([\d.]+)/)&.[](1)&.to_f || 1.0
        [ lang_tag.downcase, quality ]
      end.sort_by { |_, quality| -quality }.each do |lang_tag, _|
        return :en if lang_tag.start_with?("en")
        return :ru if lang_tag.start_with?("ru")
      end

      nil
    end

    def authenticate
      if session_record = Session.find_by_id(cookies.signed[:session_token])
        Current.session = session_record
      end
    end

    def require_authentication
      redirect_to sign_in_path unless Current.session
    end

    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end
end
