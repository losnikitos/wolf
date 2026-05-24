class ProjectsController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @projects = Project.active
    @projects = @projects.matching_phrase(@query) if @query.present?
    @projects = ordered_projects(@projects)
  end

  def collection
    @kind = params[:kind]
    @tag = params[:tag].to_s
    return head :not_found unless Project::TAG_KINDS.include?(@kind)

    @projects = ordered_projects(Project.active.with_tag(@kind, @tag))
  end

  def show
    @project = Project.friendly.find(params[:slug])
  end

  private

  def ordered_projects(scope)
    scope.order(year: :desc, name: :asc)
  end
end
