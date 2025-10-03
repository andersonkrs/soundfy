class Shopify::Collections
  extend ActiveSupport::Concern

  def initialize(shop)
    @shop = shop
  end

  def in_batches(of:, after: nil, &block)
    enum = GetCollectionsQuery.enumerator(limit: of, after: after)

    return enum.each(&block) if block_given?

    enum
  end

  def import!(api_collections)
    records = api_collections.map { |api_collection|
      {
        shopify_uuid: GlobalID.parse(api_collection.id).model_id,
        title: api_collection.title
      }
    }

    @shop.collections.upsert_all(
      records,
      record_timestamps: true,
      update_only: %i[title],
      unique_by: %i[shop_id shopify_uuid]
    )
  end
end
