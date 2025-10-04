class CleanupOldRecordingTables < ActiveRecord::Migration[8.1]
  def change
    # Remove audio_id foreign keys
    remove_foreign_key :album_tracks, :audios if foreign_key_exists?(:album_tracks, :audios)
    remove_foreign_key :albums, :audios if foreign_key_exists?(:albums, :audios)
    remove_foreign_key :single_tracks, :audios if foreign_key_exists?(:single_tracks, :audios)

    # Remove audio_id references and indexes
    if column_exists?(:album_tracks, :audio_id)
      remove_index :album_tracks, :audio_id if index_exists?(:album_tracks, :audio_id)
      remove_column :album_tracks, :audio_id # standard:disable Rails/ReversibleMigration
    end

    if column_exists?(:albums, :audio_id)
      remove_index :albums, :audio_id if index_exists?(:albums, :audio_id)
      remove_column :albums, :audio_id # standard:disable Rails/ReversibleMigration
    end

    if column_exists?(:single_tracks, :audio_id)
      remove_index :single_tracks, :audio_id if index_exists?(:single_tracks, :audio_id)
      remove_column :single_tracks, :audio_id # standard:disable Rails/ReversibleMigration
    end

    # Drop the audios table
    drop_table :audios, if_exists: true do |t|
      t.bigint "shop_id", null: false
      t.string "recordable_type", null: false
      t.bigint "recordable_id", null: false
      t.bigint "product_id", null: false
      t.bigint "variant_id", null: false
      t.integer "duration_seconds"
      t.datetime "archived_at"
      t.timestamps
    end
  end
end
