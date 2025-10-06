class Shopify::Products
  extend ActiveSupport::Concern

  def initialize(shop)
    @shop = shop
  end

  def in_batches(of:, after: nil, &block)
    GetProductsQuery.enumerator(limit: of, after: after, &block)
  end

  def import!(api_products)
    # Import products
    product_records = api_products.map { |api_product|
      {
        shopify_uuid: GlobalID.parse(api_product.id).model_id,
        title: api_product.title,
        status: api_product.status&.downcase,
        image_url: api_product.featured_image&.url
      }
    }

    @shop.products.upsert_all(
      product_records,
      record_timestamps: true,
      update_only: %i[title status image_url],
      unique_by: %i[shop_id shopify_uuid]
    )

    # Import variants for each product
    api_products.each do |api_product|
      next if api_product.variants.nil? || api_product.variants.nodes.empty?

      product = @shop.products.find_by(shopify_uuid: GlobalID.parse(api_product.id).model_id)
      next unless product

      import_variants!(product, api_product.variants.nodes)
    end
  end

  private

  def import_variants!(product, api_variants)
    variant_records = api_variants.map { |api_variant|
      {
        shop_id: @shop.id,
        shopify_uuid: GlobalID.parse(api_variant.id).model_id,
        title: api_variant.title
      }
    }

    product.variants.upsert_all(
      variant_records,
      record_timestamps: true,
      update_only: %i[title],
      unique_by: %i[shop_id shopify_uuid]
    )
  end
end
