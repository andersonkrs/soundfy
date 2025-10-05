require "active_job/continuable"

class Shopify::SyncProductsJob < ApplicationJob
  include ActiveJob::Continuable

  def perform(shop:)
    shop.with_shopify_session do
      step :process do |step|
        shop.shopify_products.in_batches(of: 10, after: step.cursor) do |records, cursor|
          shop.shopify_products.import!(records)

          step.set! cursor
        end
      end
    end
  end
end
