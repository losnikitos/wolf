class AddEmbeddingToMediaAppearances < ActiveRecord::Migration[8.1]
  def change
    add_column :media_appearances, :embedding, :binary
  end
end
