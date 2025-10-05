class Shopify::Webhooks::AppUninstalledJob < ApplicationJob
  extend ShopifyAPI::Webhooks::Handler
  include ShopScoped

  def perform(shop_domain:, webhook:)
    Current.shop.with_lock do
      Current.shop.uninstall
      Current.shop.save(validate: false)
    end
  end
end
