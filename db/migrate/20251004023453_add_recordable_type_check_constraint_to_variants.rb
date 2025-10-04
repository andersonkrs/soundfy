class AddRecordableTypeCheckConstraintToVariants < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :variants,
      "recordable_type IS NULL OR recordable_type IN ('SingleTrack', 'Album', 'AlbumTrack')",
      name: "check_variants_recordable_type"
  end
end
