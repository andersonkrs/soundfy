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

ActiveRecord::Schema[8.1].define(version: 2025_10_04_023453) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "album_tracks", force: :cascade do |t|
    t.bigint "album_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_album_tracks_on_album_id"
    t.index ["shop_id", "album_id", "position"], name: "index_album_tracks_on_shop_id_and_album_id_and_position", unique: true
  end

  create_table "albums", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_albums_on_shop_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "shop_id", null: false
    t.string "shopify_uuid", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "shopify_uuid"], name: "index_collections_on_shop_id_and_shopify_uuid", unique: true
    t.index ["shop_id"], name: "index_collections_on_shop_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "shop_id", null: false
    t.string "shopify_uuid", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["shop_id", "shopify_uuid"], name: "index_products_on_shop_id_and_shopify_uuid", unique: true
    t.index ["shop_id"], name: "index_products_on_shop_id"
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

  create_table "single_tracks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "shop_id", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_single_tracks_on_shop_id"
  end

  create_table "variants", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.integer "duration_seconds"
    t.bigint "product_id", null: false
    t.bigint "recordable_id"
    t.string "recordable_type"
    t.bigint "shop_id", null: false
    t.string "shopify_uuid", null: false
    t.string "title"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_variants_on_product_id"
    t.index ["shop_id", "id"], name: "index_variants_on_shop_and_id_for_active_recordings", unique: true, where: "(((type)::text = 'Recording'::text) AND (archived_at IS NULL))"
    t.index ["shop_id", "recordable_type", "recordable_id"], name: "index_variants_on_shop_and_recordable"
    t.index ["shop_id", "shopify_uuid"], name: "index_variants_on_shop_id_and_shopify_uuid", unique: true
    t.index ["shop_id", "type"], name: "index_variants_on_shop_id_and_type"
    t.index ["shop_id"], name: "index_variants_on_shop_id"
    t.check_constraint "recordable_type IS NULL OR (recordable_type::text = ANY (ARRAY['SingleTrack'::character varying, 'Album'::character varying, 'AlbumTrack'::character varying]::text[]))", name: "check_variants_recordable_type"
    t.check_constraint "type IS NULL OR type::text = 'Recording'::text", name: "check_variants_type"
  end

  add_foreign_key "album_tracks", "albums"
  add_foreign_key "album_tracks", "shops"
  add_foreign_key "albums", "shops"
  add_foreign_key "collections", "shops"
  add_foreign_key "products", "shops"
  add_foreign_key "single_tracks", "shops"
  add_foreign_key "variants", "products"
  add_foreign_key "variants", "shops"
end
