class HomeController < ApplicationController
  def index
    @favorite_projects = Project.active.favorites.includes(:client).order(year: :desc, name: :asc)
  end
end
