class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorageWithScopes

  include Uninstallable
  include Shopify::Collectionable

  def api_version
    ShopifyApp.configuration.api_version
  end

  def activate_api_session
    ShopifyAPI::Context.activate_session(shopify_session)
  end

  def shopify_session
    ShopifyAPI::Auth::Session.new(
      shop: shopify_domain,
      access_token: shopify_token
    )
  end
end
