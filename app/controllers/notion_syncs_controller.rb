class NotionSyncsController < ApplicationController
  before_action :require_authentication

  def create
    record = Notion::RecordSyncer.find(params[:record_type], params[:slug])
    result = Notion::RecordSyncer.sync!(record)

    redirect_back fallback_location: root_path, notice: sync_notice(result)
  rescue KeyError, ActiveRecord::RecordNotFound
    head :not_found
  rescue StandardError => e
    Rails.logger.error("[NotionSyncsController] Sync failed: #{e.class} #{e.message}")
    redirect_back fallback_location: root_path, alert: "Could not sync from Notion."
  end

  private

  def sync_notice(result)
    case result.updated + result.created
    when 0 then "Already up to date."
    else "Synced from Notion."
    end
  end
end
