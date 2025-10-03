class Shopify::AuthenticatedController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::EnsureInstalled
  include ShopifyApp::ShopAccessScopesVerification

  before_action :set_current_shop

  private

  def set_current_shop
    Current.shop ||= Shop.find_by(shopify_domain: jwt_shopify_domain)
  end
end
