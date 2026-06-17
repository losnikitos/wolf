class CreateBlogPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_posts do |t|
      t.integer :telegram_message_id, null: false
      t.bigint :telegram_grouped_id
      t.json :telegram_message_ids, null: false, default: []
      t.string :slug
      t.string :title
      t.text :body
      t.json :entities, null: false, default: []
      t.json :poll
      t.datetime :published_at, null: false
      t.datetime :edited_at
      t.integer :views
      t.json :reactions, null: false, default: []
      t.datetime :imported_at
      t.boolean :archived, null: false, default: false

      t.timestamps
    end

    add_index :blog_posts, :telegram_message_id, unique: true
    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :published_at
  end
end
