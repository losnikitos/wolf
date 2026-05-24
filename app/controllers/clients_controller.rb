class ClientsController < ApplicationController
  def index
    clients = Client.active.ordered
    other_group = t("clients.other_group")
    @clients_by_group = clients.group_by { |client| client.client_group.presence || other_group }
    @group_names = @clients_by_group.keys.sort_by { |name| [ name == other_group ? 1 : 0, name ] }
    @project_counts = Project.active.where(client_id: clients.map(&:id)).group(:client_id).count
  end

  def show
    @client = Client.friendly.find(params[:slug])
    @projects = Project.active.where(client: @client).order(year: :desc, name: :asc)
  end
end
