class AddPublicationFieldsToMediaAppearances < ActiveRecord::Migration[8.1]
  def change
    add_column :media_appearances, :url, :string
    add_column :media_appearances, :publication, :string
  end
end
