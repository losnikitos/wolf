class AddEmbeddingToTalks < ActiveRecord::Migration[8.1]
  def change
    add_column :talks, :embedding, :binary
  end
end
