class Shopify::AuthenticatedController < ApplicationController
  include ShopifyApp::EnsureHasSession
  include ShopifyApp::ShopAccessScopesVerification
  include ShopifyApp::FrameAncestors

  # Skip CSRF verification for JWT-authenticated requests
  # JWT itself provides CSRF protection
  protect_from_forgery with: :null_session, if: :jwt_request?

  before_action :set_current_shop

  private

  def set_current_shop
    Current.shop ||= Shop.find_by(shopify_domain: jwt_shopify_domain)
  end

  def jwt_request?
    request.authorization.present?
  end
end
