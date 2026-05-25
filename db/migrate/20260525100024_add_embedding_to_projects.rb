class AddEmbeddingToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :embedding, :binary
  end
end
