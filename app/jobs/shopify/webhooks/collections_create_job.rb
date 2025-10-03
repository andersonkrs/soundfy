class Shopify::Webhooks::CollectionsCreateJob < ApplicationJob
  include ShopScoped

  def perform(shop_domain:, webhook:)
  end
end
