class CreateCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :collections do |t|
      t.string :shopify_uuid, null: false
      t.string :title, null: false
      t.references :shop, null: false, foreign_key: true

      t.timestamps
    end

    add_index :collections, [ :shop_id, :shopify_uuid ], unique: true
  end
end
