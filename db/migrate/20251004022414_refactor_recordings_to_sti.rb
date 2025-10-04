class RefactorRecordingsToSti < ActiveRecord::Migration[8.1]
  def change
    # Add STI type column to variants
    add_column :variants, :type, :string
    add_index :variants, [:shop_id, :type]

    # Add recording-specific fields to variants
    add_column :variants, :recordable_type, :string
    add_column :variants, :recordable_id, :bigint
    add_column :variants, :duration_seconds, :integer
    add_column :variants, :archived_at, :datetime

    # Add index for polymorphic recordable association
    add_index :variants, [:shop_id, :recordable_type, :recordable_id], 
              name: 'index_variants_on_shop_and_recordable'

    # Add unique constraint for active recordings (one per variant)
    add_index :variants, [:shop_id, :id], 
              unique: true, 
              where: "type = 'Recording' AND archived_at IS NULL",
              name: 'index_variants_on_shop_and_id_for_active_recordings'

    # Single tracks table (recordable type)
    create_table :single_tracks do |t|
      t.references :shop, null: false, foreign_key: true, index: true
      t.timestamps
    end

    # Albums table (recordable type)
    create_table :albums do |t|
      t.references :shop, null: false, foreign_key: true, index: true
      t.timestamps
    end

    # Album tracks table (recordable type - each track in an album)
    create_table :album_tracks do |t|
      t.references :shop, null: false, foreign_key: true, index: false
      t.references :album, null: false, foreign_key: true
      t.integer :position, null: false
      t.timestamps
    end

    add_index :album_tracks, [:shop_id, :album_id, :position], unique: true
  end
end
