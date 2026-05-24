class AddBodyToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :body, :json
  end
end
