class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :notion_page_id, null: false
      t.string :notion_url
      t.string :name
      t.string :client
      t.string :status
      t.string :project_type
      t.string :city
      t.integer :year
      t.string :cover_url
      t.boolean :favorite, null: false, default: false
      t.boolean :archived, null: false, default: false
      t.json :roles, null: false, default: []
      t.json :deliverables, null: false, default: []
      t.json :directions, null: false, default: []
      t.datetime :notion_created_at
      t.datetime :notion_last_edited_at
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :projects, :notion_page_id, unique: true
    add_index :projects, :status
    add_index :projects, :year
  end
end
