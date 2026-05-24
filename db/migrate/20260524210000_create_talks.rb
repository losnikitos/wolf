class CreateTalks < ActiveRecord::Migration[8.1]
  def change
    create_table :talks do |t|
      t.string :notion_page_id, null: false
      t.string :notion_url
      t.string :name
      t.text :topic
      t.string :location
      t.string :organizer
      t.date :talk_date
      t.references :project, foreign_key: true
      t.string :slug
      t.boolean :archived, default: false, null: false
      t.json :body, default: [], null: false
      t.datetime :notion_created_at
      t.datetime :notion_last_edited_at
      t.datetime :last_synced_at
      t.datetime :page_content_last_synced_at

      t.timestamps
    end

    add_index :talks, :notion_page_id, unique: true
    add_index :talks, :slug, unique: true
    add_index :talks, :talk_date
  end
end
