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

ActiveRecord::Schema[8.1].define(version: 2025_09_28_133846) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "shop_id", null: false
    t.string "shopify_uuid", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "shopify_uuid"], name: "index_collections_on_shop_id_and_shopify_uuid", unique: true
    t.index ["shop_id"], name: "index_collections_on_shop_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "access_scopes", default: "", null: false
    t.datetime "created_at", null: false
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.datetime "uninstalled_at"
    t.datetime "updated_at", null: false
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  add_foreign_key "collections", "shops"
end
