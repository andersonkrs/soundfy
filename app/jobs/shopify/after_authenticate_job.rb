class Shopify::AfterAuthenticateJob < ApplicationJob
  def perform(shop_domain:)
    shop = Shop.find_by!(shopify_domain: shop_domain)

    Shopify::SyncCollectionsJob.perform_later(shop: shop)
  end
end
