class AddBasicShopifyModels < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :shopify_uuid, null: false
      t.string :title
      t.datetime :discarded_at, null: true
      t.timestamps
    end

    add_index :products, [:shop_id, :shopify_uuid], unique: true

    # Variants table
    create_table :variants do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :shopify_uuid, null: false
      t.string :title
      t.references :product, null: false, foreign_key: true
      t.datetime :discarded_at, null: true
      t.timestamps
    end

    add_index :variants, [:shop_id, :shopify_uuid], unique: true
    add_index :variants, [:product_id]
  end
end
