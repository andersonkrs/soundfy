class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorageWithScopes

  include Uninstallable
  include Shopify::Collectionable
  include Shopify::Productable

  has_many :recordings, as: :recordable, dependent: :destroy

  encrypts :shopify_domain, deterministic: true, downcase: true
  encrypts :shopify_token

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
