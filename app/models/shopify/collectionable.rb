module Shopify::Collectionable
  extend ActiveSupport::Concern

  included do
    has_many :collections, dependent: :destroy, inverse_of: :shop
  end

  def shopify_collections
    Shopify::Collections.new(self)
  end
end
