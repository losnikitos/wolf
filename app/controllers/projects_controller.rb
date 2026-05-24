class ProjectsController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @projects = Project.active
    @projects = @projects.matching_phrase(@query) if @query.present?
    @projects = @projects.order(year: :desc, name: :asc)
  end

  def show
    @project = Project.friendly.find(params[:slug])
  end
end
