class Shopify::Webhooks::AppUninstalledJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(shop_domain:, webhook:)
    Current.shop = Shop.find_by!(shopify_domain: shop_domain)

    Current.shop.with_lock do
      Current.shop.uninstall
      Current.shop.save(validate: false)
    end
  end
end
