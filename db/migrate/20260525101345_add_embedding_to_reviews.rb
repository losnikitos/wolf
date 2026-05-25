class AddEmbeddingToReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :reviews, :embedding, :binary
  end
end
