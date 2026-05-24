class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip

    if @query.present?
      @projects = Project.active.matching_name(@query).order(year: :desc, name: :asc)
      @clients = Client.active.matching_name(@query).ordered
      @media_appearances = MediaAppearance.active.matching_name(@query).ordered
      @talks = Talk.active.matching_name(@query).ordered
    else
      @projects = Project.none
      @clients = Client.none
      @media_appearances = MediaAppearance.none
      @talks = Talk.none
    end
  end
end
