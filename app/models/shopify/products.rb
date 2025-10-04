class Shopify::Products
  extend ActiveSupport::Concern

  def initialize(shop)
    @shop = shop
  end

  def in_batches(of:, after: nil, &block)
  end

  def import!(api_collections)
    api_collections.map { |api_collection|
      {
        shopify_uuid: GlobalID.parse(api_collection.id).model_id,
        title: api_collection.title
      }
    }
  end
end
