class HomeController < ApplicationController
  def index
    @favorite_projects = Project.active.favorites.includes(:client).order(year: :desc, name: :asc).limit(4)
  end
end
