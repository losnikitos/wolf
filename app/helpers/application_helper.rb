module ApplicationHelper
  include NotionBodyHelper
  include NotionHelper

  def tw_label_classes
    "mb-1 block text-sm font-medium text-zinc-700"
  end

  def tw_input_classes
    "mt-1 block w-full rounded-xl border border-zinc-200 bg-white px-3 py-2 text-zinc-900 shadow-sm placeholder:text-zinc-400 focus:border-zinc-900 focus:outline-none focus:ring-2 focus:ring-zinc-900/20 sm:text-sm"
  end

  def tw_btn_primary_classes
    "inline-flex w-full cursor-pointer items-center justify-center rounded-xl bg-zinc-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-zinc-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-zinc-900"
  end

  def tw_btn_secondary_classes
    "inline-flex w-full cursor-pointer items-center justify-center rounded-xl border border-zinc-200 bg-white px-4 py-2.5 text-sm font-semibold text-zinc-900 transition hover:bg-zinc-50 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-zinc-900"
  end

  def tw_text_link_classes
    "font-medium text-zinc-900 underline decoration-zinc-300 underline-offset-4 transition hover:decoration-zinc-900"
  end

  def tw_alert_success_classes
    "mb-4 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-zinc-900"
  end

  def tw_alert_error_classes
    "mb-4 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-zinc-900"
  end

  def localized_year_label(year)
    year == "Unknown" ? t("shared.unknown") : year
  end

  def registration_enabled?
    RegistrationsController::REGISTRATION_ENABLED
  end
end
