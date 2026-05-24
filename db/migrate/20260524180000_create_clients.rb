class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :notion_page_id, null: false
      t.string :notion_url
      t.string :name
      t.string :client_group
      t.string :slug
      t.boolean :archived, default: false, null: false
      t.datetime :notion_created_at
      t.datetime :notion_last_edited_at
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :clients, :notion_page_id, unique: true
    add_index :clients, :slug, unique: true
    add_index :clients, :client_group

    add_reference :projects, :client, foreign_key: true
    remove_column :projects, :client, :string
  end
end
