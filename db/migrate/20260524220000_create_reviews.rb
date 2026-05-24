class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.string :notion_page_id, null: false
      t.string :notion_url
      t.string :name
      t.string :slug
      t.boolean :archived, default: false, null: false
      t.json :body, default: [], null: false
      t.datetime :notion_created_at
      t.datetime :notion_last_edited_at
      t.datetime :last_synced_at
      t.datetime :page_content_last_synced_at

      t.timestamps
    end

    add_index :reviews, :notion_page_id, unique: true
    add_index :reviews, :slug, unique: true
    add_index :reviews, :notion_created_at
  end
end
