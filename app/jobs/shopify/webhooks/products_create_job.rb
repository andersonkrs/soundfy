class Shopify::Webhooks::ProductsCreateJob < ApplicationJob
  include ShopScoped

  def perform(shop_domain:, webhook:)
    product = Current.shop.products.create_or_find_by!(shopify_uuid: webhook["id"])

    product.with_non_blocking_lock!("FOR NO KEY UPDATE SKIP LOCKED") do
      return if product.discarded?

      product.title = webhook["title"]
      product.status = webhook["status"]&.downcase
      product.image_url = webhook.dig("image", "src") || webhook.dig("images", 0, "src")
      product.save!(validate: false)

      if webhook["variants"].present?
        return if product.discarded?

        variant_records = webhook["variants"].map { |variant_data|
          {
            shop_id: Current.shop.id,
            shopify_uuid: variant_data["id"],
            title: variant_data["title"]
          }
        }

        product.variants.upsert_all(
          variant_records,
          record_timestamps: true,
          unique_by: %i[shop_id shopify_uuid]
        )
      end
    end
  end
end
