class Shopify::HomeController < Shopify::AuthenticatedController
  def index
    render inertia: "Home"
  end
end
