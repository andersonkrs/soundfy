module ShopScoped
  extend ActiveSupport::Concern

  included do
    around_perform do |job, block|
      case job.arguments
      in [{shop: shop}, *]
        with_shop(shop, &block)
      in [{shop_domain: shop_domain}, *]
        shop = Shop.find_by(shopify_domain: shop_domain)

        if shop.nil?
          logger.error("#{self.class} failed: cannot find shop with domain '#{shop_domain}'")

          raise ActiveRecord::RecordNotFound, "Shop Not Found"
        end

        with_shop(shop, &block)
      else
        return block.call
      end

      with_shop(shop, &block)
    end
  end

  private

  def with_shop(shop, &block)
    Current.set(shop: shop) do
      shop.with_shopify_session do
        block.call
      end
    end
  end
end
