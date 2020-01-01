# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_01_01_131615) do

  create_table "authors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "favorite_book"
    t.string "favorite_author"
    t.text "bio"
    t.string "uri_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "archive_id"
    t.text "contacts"
  end

  create_table "comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "orig_id"
    t.text "body"
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "author_id"
    t.integer "story_id"
  end

  create_table "stories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "orig_id"
    t.integer "archive_id"
    t.string "author_short"
    t.string "author_name"
    t.string "title"
    t.string "photo_url"
    t.string "photo_link"
    t.string "photo_title"
    t.string "photo_author"
    t.boolean "is_mature"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.text "sequels"
    t.text "prequels"
    t.text "cached_tags"
    t.text "body"
  end

  create_table "tags", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "tag"
    t.text "story_ids"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "story_count", default: 0
  end

end
