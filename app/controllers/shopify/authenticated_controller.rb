class Shopify::AuthenticatedController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::EnsureInstalled
  include ShopifyApp::ShopAccessScopesVerification

  # Skip CSRF verification for JWT-authenticated requests
  # JWT itself provides CSRF protection
  protect_from_forgery with: :null_session, if: :jwt_request?

  before_action :set_current_shop

  # Override to prefer JWT shop domain over query params
  # This allows redirects to work without requiring shop/host query parameters
  def current_shopify_domain
    jwt_shopify_domain || sanitized_shop_name || current_shopify_session&.shop
  end

  private

  def set_current_shop
    Current.shop ||= Shop.find_by(shopify_domain: current_shopify_domain)
  end

  def jwt_request?
    request.authorization.present?
  end
end
