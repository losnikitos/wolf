class ProjectsController < ApplicationController
  def index
    @projects = Project.active.order(year: :desc, name: :asc)
  end

  def show
    @project = Project.friendly.find(params[:slug])
  end
end
