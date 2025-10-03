require "active_job/continuable"

class Shopify::SyncCollectionsJob < ApplicationJob
  include ShopifySession
  include ActiveJob::Continuable

  def perform(shop:)
    step :process do |step|
      shop.shopify_collections.in_batches(of: 25, after: step.cursor) do |records, cursor|
        shop.shopify_collections.import!(records)

        step.set! cursor
      end
    end
  end
end
