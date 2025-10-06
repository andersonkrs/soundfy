class AddImageUrlAndStatusToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :image_url, :string
    add_column :products, :status, :string

    add_check_constraint :products,
      "status IS NULL OR status IN ('active', 'archived', 'draft', 'unlisted')",
      name: "check_products_status"
  end
end
