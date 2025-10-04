class AddTypeCheckConstraintToVariants < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :variants, "type IS NULL OR type = 'Recording'", name: "check_variants_type"
  end
end
