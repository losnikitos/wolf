class TalksController < ApplicationController
  def index
    talks = Talk.active.ordered
    @talks_by_year = talks.group_by { |talk| talk.talk_year || "Unknown" }
    @year_names = @talks_by_year.keys.sort_by { |year| year == "Unknown" ? 0 : year.to_i }.reverse
  end

  def show
    @talk = Talk.friendly.find(params[:slug])
    @recommended_talks = @talk.recommended
  end
end
