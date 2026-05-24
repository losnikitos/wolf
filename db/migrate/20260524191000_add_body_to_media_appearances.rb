class AddBodyToMediaAppearances < ActiveRecord::Migration[8.1]
  def change
    add_column :media_appearances, :body, :json, default: [], null: false
  end
end
