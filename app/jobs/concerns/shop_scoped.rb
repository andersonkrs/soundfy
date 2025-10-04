module ShopScoped
  extend ActiveSupport::Concern

  included do
    attr_accessor :shop

    around_perform do |job, block|
      case job.arguments
      in [{shop: shop}, *]
        self.shop = shop
      in [{shop_domain: shop_domain}, *]
        self.shop = Shop.find_by(shopify_domain: shop_domain)

        if shop.nil?
          logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")

          raise ActiveRecord::RecordNotFound, "Shop Not Found"
        end
      else
        return block.call
      end

      shop.with_shopify_session(&block)
    end
  end

  private

  def wrap_shopify_session(&block)
  end
end
