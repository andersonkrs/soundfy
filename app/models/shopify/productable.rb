module Shopify::Productable
  extend ActiveSupport::Concern

  included do
    has_many :products, dependent: :destroy, inverse_of: :shop
    has_many :variants, dependent: :destroy, inverse_of: :shop
  end

  def shopify_products
    Shopify::Products.new(self)
  end
end
