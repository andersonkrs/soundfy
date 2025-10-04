class Variant < ApplicationRecord
  belongs_to :shop
  belongs_to :product

  validate :same_shop_as_product

  # Scope for regular variants (not STI subclasses)
  scope :regular, -> { where(type: nil) }

  private

  def same_shop_as_product
    if product && product.shop_id != shop_id
      errors.add(:product, "must belong to the same shop")
    end
  end
end
