class CreateMediaAppearances < ActiveRecord::Migration[8.1]
  def change
    create_table :media_appearances do |t|
      t.string :notion_page_id, null: false
      t.string :notion_url
      t.string :name
      t.text :topic
      t.string :location
      t.string :organizer
      t.date :appearance_date
      t.references :project, foreign_key: true
      t.string :slug
      t.boolean :archived, default: false, null: false
      t.datetime :notion_created_at
      t.datetime :notion_last_edited_at
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :media_appearances, :notion_page_id, unique: true
    add_index :media_appearances, :slug, unique: true
    add_index :media_appearances, :appearance_date
  end
end
