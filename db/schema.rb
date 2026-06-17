# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_17_120000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "blog_posts", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.json "entities", default: [], null: false
    t.datetime "imported_at"
    t.json "poll"
    t.datetime "published_at", null: false
    t.json "reactions", default: [], null: false
    t.string "slug"
    t.bigint "telegram_grouped_id"
    t.integer "telegram_message_id", null: false
    t.json "telegram_message_ids", default: [], null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "views"
    t.index ["published_at"], name: "index_blog_posts_on_published_at"
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
    t.index ["telegram_message_id"], name: "index_blog_posts_on_telegram_message_id", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.string "client_group"
    t.datetime "created_at", null: false
    t.datetime "last_synced_at"
    t.string "name"
    t.datetime "notion_created_at"
    t.datetime "notion_last_edited_at"
    t.string "notion_page_id", null: false
    t.string "notion_url"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["client_group"], name: "index_clients_on_client_group"
    t.index ["notion_page_id"], name: "index_clients_on_notion_page_id", unique: true
    t.index ["slug"], name: "index_clients_on_slug", unique: true
  end

  create_table "media_appearances", force: :cascade do |t|
    t.date "appearance_date"
    t.boolean "archived", default: false, null: false
    t.json "body", default: [], null: false
    t.datetime "created_at", null: false
    t.binary "embedding"
    t.datetime "last_synced_at"
    t.string "location"
    t.string "name"
    t.datetime "notion_created_at"
    t.datetime "notion_last_edited_at"
    t.string "notion_page_id", null: false
    t.string "notion_url"
    t.string "organizer"
    t.datetime "page_content_last_synced_at"
    t.integer "project_id"
    t.string "publication"
    t.string "slug"
    t.text "topic"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["appearance_date"], name: "index_media_appearances_on_appearance_date"
    t.index ["notion_page_id"], name: "index_media_appearances_on_notion_page_id", unique: true
    t.index ["project_id"], name: "index_media_appearances_on_project_id"
    t.index ["slug"], name: "index_media_appearances_on_slug", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.json "body", default: [], null: false
    t.string "city"
    t.integer "client_id"
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.json "deliverables", default: [], null: false
    t.json "directions", default: [], null: false
    t.binary "embedding"
    t.boolean "favorite", default: false, null: false
    t.datetime "last_synced_at"
    t.string "name"
    t.datetime "notion_created_at"
    t.datetime "notion_last_edited_at"
    t.string "notion_page_id", null: false
    t.string "notion_url"
    t.datetime "page_content_last_synced_at"
    t.string "project_type"
    t.json "roles", default: [], null: false
    t.string "slug"
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["client_id"], name: "index_projects_on_client_id"
    t.index ["notion_page_id"], name: "index_projects_on_notion_page_id", unique: true
    t.index ["slug"], name: "index_projects_on_slug", unique: true
    t.index ["status"], name: "index_projects_on_status"
    t.index ["year"], name: "index_projects_on_year"
  end

  create_table "reviews", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.json "body", default: [], null: false
    t.datetime "created_at", null: false
    t.binary "embedding"
    t.datetime "last_synced_at"
    t.string "name"
    t.datetime "notion_created_at"
    t.datetime "notion_last_edited_at"
    t.string "notion_page_id", null: false
    t.string "notion_url"
    t.datetime "page_content_last_synced_at"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["notion_created_at"], name: "index_reviews_on_notion_created_at"
    t.index ["notion_page_id"], name: "index_reviews_on_notion_page_id", unique: true
    t.index ["slug"], name: "index_reviews_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "talks", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.json "body", default: [], null: false
    t.datetime "created_at", null: false
    t.binary "embedding"
    t.datetime "last_synced_at"
    t.string "location"
    t.string "name"
    t.datetime "notion_created_at"
    t.datetime "notion_last_edited_at"
    t.string "notion_page_id", null: false
    t.string "notion_url"
    t.string "organizer"
    t.datetime "page_content_last_synced_at"
    t.integer "project_id"
    t.string "slug"
    t.date "talk_date"
    t.text "topic"
    t.datetime "updated_at", null: false
    t.index ["notion_page_id"], name: "index_talks_on_notion_page_id", unique: true
    t.index ["project_id"], name: "index_talks_on_project_id"
    t.index ["slug"], name: "index_talks_on_slug", unique: true
    t.index ["talk_date"], name: "index_talks_on_talk_date"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "media_appearances", "projects"
  add_foreign_key "projects", "clients"
  add_foreign_key "sessions", "users"
  add_foreign_key "talks", "projects"
end
