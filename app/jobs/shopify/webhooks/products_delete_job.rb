class Shopify::Webhooks::ProductsDeleteJob < ApplicationJob
  include ShopScoped

  retry_on ActiveRecord::RecordNotFound, wait: :polynomially_longer

  def perform(shop_domain:, webhook:)
    product = Current.shop.products.find_by!(shopify_uuid: webhook["id"])
    return if product.discarded?

    product.with_non_blocking_lock!("FOR NO KEY UPDATE SKIP LOCKED") do
      product.discard!
    end
  end
end
