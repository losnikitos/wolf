class ProjectsController < ApplicationController
  def index
    @projects = ordered_projects(Project.active)
  end

  def collection
    @kind = params[:kind]
    @tag = params[:tag].to_s
    return head :not_found unless Project::TAG_KINDS.include?(@kind)

    @projects = ordered_projects(Project.active.with_tag(@kind, @tag))
  end

  def show
    if params[:client_slug].present?
      @client = Client.friendly.find(params[:client_slug])
      @project = @client.projects.friendly.find(params[:project_slug])
    else
      @project = Project.friendly.find(params[:slug])
    end

    @recommended_projects = @project.recommended
  end

  private

  def ordered_projects(scope)
    scope.order(year: :desc, name: :asc)
  end
end
