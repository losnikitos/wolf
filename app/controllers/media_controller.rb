class MediaController < ApplicationController
  def index
    appearances = MediaAppearance.active.ordered
    @appearances_by_year = appearances.group_by { |appearance| appearance.appearance_year || "Unknown" }
    @year_names = @appearances_by_year.keys.sort_by { |year| year == "Unknown" ? 0 : year.to_i }.reverse
  end

  def show
    @media_appearance = MediaAppearance.friendly.find(params[:slug])
    @recommended_media_appearances = @media_appearance.recommended
  end
end
