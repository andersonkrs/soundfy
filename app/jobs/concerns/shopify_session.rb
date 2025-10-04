module ShopifySession
  extend ActiveSupport::Concern

  included do
    around_perform do |job, block|
      case job.arguments
      in [{shop: shop}, *]
        shop.with_shopify_session(&block)
      else
        block.call
      end
    end
  end
end
