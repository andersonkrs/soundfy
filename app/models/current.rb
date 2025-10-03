class Current < ActiveSupport::CurrentAttributes
  attribute :shop

  # def shop=(shop)
  #   super(shop)
  #   Rollbar.scope!(shopify_domain: shop&.shopify_domain)
  # end
  #
  # after_reset { Rollbar.scope!(shopify_domain: nil) }
end
