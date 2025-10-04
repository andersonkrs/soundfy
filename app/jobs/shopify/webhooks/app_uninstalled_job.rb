class Shopify::Webhooks::AppUninstalledJob < ApplicationJob
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(shop:, body:)
      perform_later(shop_domain: shop, webhook: body)
    end
  end

  def perform(shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    if shop.nil?
      logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")

      raise ActiveRecord::RecordNotFound, "Shop Not Found"
    end

    logger.info("#{self.class} started for shop '#{shop_domain}'")

    shop.with_lock do
      shop.uninstall
      shop.save(validate: false)
    end
  end
end
