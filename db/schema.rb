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

ActiveRecord::Schema[8.1].define(version: 2026_05_12_230000) do
  create_table "projects", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.string "city"
    t.string "client"
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.json "deliverables", default: [], null: false
    t.json "directions", default: [], null: false
    t.boolean "favorite", default: false, null: false
    t.datetime "last_synced_at"
    t.string "name"
    t.datetime "notion_created_at"
    t.datetime "notion_last_edited_at"
    t.string "notion_page_id", null: false
    t.string "notion_url"
    t.string "project_type"
    t.json "roles", default: [], null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["notion_page_id"], name: "index_projects_on_notion_page_id", unique: true
    t.index ["status"], name: "index_projects_on_status"
    t.index ["year"], name: "index_projects_on_year"
  end
end
