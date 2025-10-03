class AddUninstalledAtToShops < ActiveRecord::Migration[8.1]
  def change
    add_column :shops, :uninstalled_at, :datetime, null: true, default: nil
  end
end
