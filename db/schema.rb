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

ActiveRecord::Schema[8.0].define(version: 2025_09_07_130901) do
  create_table "contents", force: :cascade do |t|
    t.string "theme", limit: 256, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "theme" ], name: "index_contents_on_theme"
  end

  create_table "tracks", force: :cascade do |t|
    t.integer "content_id", null: false
    t.string "status", default: "pending", null: false
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "content_id" ], name: "index_tracks_on_content_id"
    t.index [ "status" ], name: "index_tracks_on_status"
  end

  add_foreign_key "tracks", "contents"
end
