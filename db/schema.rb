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

ActiveRecord::Schema[8.0].define(version: 2025_09_08_002807) do
  create_table "artworks", force: :cascade do |t|
    t.integer "content_id", null: false
    t.json "image_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "content_id" ], name: "index_artworks_on_content_id"
  end

  create_table "audios", force: :cascade do |t|
    t.integer "content_id", null: false
    t.string "status"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "audio_data"
    t.index [ "content_id" ], name: "index_audios_on_content_id"
  end

  create_table "contents", force: :cascade do |t|
    t.string "theme", limit: 256, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration", default: 3, null: false
    t.text "audio_prompt", null: false
    t.index [ "theme" ], name: "index_contents_on_theme"
  end

  create_table "music_generations", force: :cascade do |t|
    t.integer "content_id", null: false
    t.string "task_id", null: false
    t.string "status", null: false
    t.text "prompt", null: false
    t.string "generation_model", null: false
    t.json "api_response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "metadata", default: {}, null: false
    t.index [ "content_id" ], name: "index_music_generations_on_content_id"
    t.index [ "status" ], name: "index_music_generations_on_status"
    t.index [ "task_id" ], name: "index_music_generations_on_task_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.integer "content_id", null: false
    t.string "status", default: "pending", null: false
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "audio_data"
    t.integer "duration"
    t.integer "music_generation_id"
    t.integer "variant_index"
    t.index [ "content_id" ], name: "index_tracks_on_content_id"
    t.index [ "music_generation_id" ], name: "index_tracks_on_music_generation_id"
    t.index [ "status" ], name: "index_tracks_on_status"
  end

  create_table "videos", force: :cascade do |t|
    t.integer "content_id", null: false
    t.string "status", default: "pending", null: false
    t.text "video_data"
    t.string "resolution"
    t.integer "file_size"
    t.integer "duration_seconds"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "content_id" ], name: "index_videos_on_content_id"
    t.index [ "status" ], name: "index_videos_on_status"
  end

  add_foreign_key "artworks", "contents"
  add_foreign_key "audios", "contents"
  add_foreign_key "music_generations", "contents"
  add_foreign_key "tracks", "contents"
  add_foreign_key "tracks", "music_generations"
  add_foreign_key "videos", "contents"
end
