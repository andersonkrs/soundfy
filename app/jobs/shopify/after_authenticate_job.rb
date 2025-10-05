class Shopify::AfterAuthenticateJob < ApplicationJob
  include ShopScoped

  def perform(shop_domain:)
    Shopify::SyncProductsJob.perform_later(shop: Current.shop)
  end
end
