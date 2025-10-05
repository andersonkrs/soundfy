# Soundfy Architecture: Shopify Data Sync

## Overview

Soundfy uses a consistent pattern for syncing data from Shopify. This document explains the architecture and how to extend it for new resources.

## Sync Architecture

### Components

Every Shopify resource that needs syncing follows this 5-part pattern:

```
1. Concern (included in Shop model)
   ├── 2. Service Class (handles data operations)
   │   └── 3. GraphQL Query (fetches from Shopify)
   ├── 4. Sync Job (full sync on install)
   └── 5. Webhook Jobs (real-time updates)
```

### Example: Products Sync

#### 1. Concern: `Shopify::Productable`

**Location**: `app/models/shopify/productable.rb`

```ruby
module Shopify::Productable
  extend ActiveSupport::Concern

  included do
    has_many :products, dependent: :destroy, inverse_of: :shop
  end

  def shopify_products
    Shopify::Products.new(self)
  end
end
```

**Purpose**: 
- Adds ActiveRecord associations to Shop
- Provides convenient accessor method
- Included in `Shop` model

#### 2. Service Class: `Shopify::Products`

**Location**: `app/models/shopify/products.rb`

```ruby
class Shopify::Products
  def initialize(shop)
    @shop = shop
  end

  def in_batches(of:, after: nil, &block)
    enum = GetProductsQuery.enumerator(limit: of, after: after)
    return enum.each(&block) if block_given?
    enum
  end

  def import!(api_products)
    product_records = api_products.map { |api_product|
      {
        shopify_uuid: GlobalID.parse(api_product.id).model_id,
        title: api_product.title
      }
    }

    @shop.products.upsert_all(
      product_records,
      record_timestamps: true,
      update_only: %i[title],
      unique_by: %i[shop_id shopify_uuid]
    )
    
    # Also import nested resources (variants)
    api_products.each do |api_product|
      import_variants!(product, api_product.variants.nodes)
    end
  end
end
```

**Purpose**:
- Encapsulates all product-related Shopify operations
- Handles batch processing with pagination
- Uses `upsert_all` for efficient bulk operations
- Manages nested resources (products → variants)

#### 3. GraphQL Query: `GetProductsQuery`

**Location**: `app/graphql/get_products_query.rb`

```ruby
class GetProductsQuery
  def self.enumerator(limit:, search: nil, after: nil)
    ShopifyGraphql::QueryEnumerator.new(
      PRODUCTS_QUERY,
      dig: [:products],
      variables: { limit: limit, after: after, query: search }
    )
  end

  PRODUCTS_QUERY = <<~GRAPHQL
    query GetProducts($limit: Int!, $after: String, $query: String) {
      products(first: $limit, after: $after, query: $query) {
        nodes {
          id
          title
          variants(first: 100) {
            nodes {
              id
              title
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  GRAPHQL
end
```

**Purpose**:
- Defines what data to fetch from Shopify
- Uses cursor-based pagination
- Returns a lazy enumerator for efficient memory usage
- Includes nested resources in single query

#### 4. Sync Job: `Shopify::SyncProductsJob`

**Location**: `app/jobs/shopify/sync_products_job.rb`

```ruby
require "active_job/continuable"

class Shopify::SyncProductsJob < ApplicationJob
  include ShopifySession
  include ActiveJob::Continuable

  def perform(shop:)
    step :process do |step|
      shop.shopify_products.in_batches(of: 25, after: step.cursor) do |records, cursor|
        shop.shopify_products.import!(records)
        step.set! cursor  # Save progress for resumability
      end
    end
  end
end
```

**Purpose**:
- Full sync of all products on shop installation
- Resumable - can be interrupted and resumed
- Batched processing for large datasets
- Triggered by `AfterAuthenticateJob`

#### 5. Webhook Jobs

**Location**: `app/jobs/shopify/webhooks/products_*_job.rb`

```ruby
# products_update_job.rb - Handle individual product updates
class Shopify::Webhooks::ProductsUpdateJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by!(shopify_domain: shop_domain)
    
    product = shop.products.find_or_initialize_by(shopify_uuid: webhook["id"].to_s)
    product.update!(title: webhook["title"], discarded_at: nil)
    
    # Also update variants
    webhook["variants"]&.each do |variant_data|
      variant = product.variants.find_or_initialize_by(
        shop: shop,
        shopify_uuid: variant_data["id"].to_s
      )
      variant.update!(title: variant_data["title"], discarded_at: nil)
    end
  end
end

# products_delete_job.rb - Handle product deletion
class Shopify::Webhooks::ProductsDeleteJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by!(shopify_domain: shop_domain)
    product = shop.products.find_by(shopify_uuid: webhook["id"].to_s)
    product&.discard!  # Soft delete
  end
end
```

**Purpose**:
- Real-time updates when merchants change products in Shopify
- Keeps local database in sync
- Handles creates, updates, and soft-deletes

## How to Add a New Shopify Resource

### Example: Adding Orders Sync

#### Step 1: Create the Concern

```ruby
# app/models/shopify/orderable.rb
module Shopify::Orderable
  extend ActiveSupport::Concern

  included do
    has_many :orders, dependent: :destroy, inverse_of: :shop
  end

  def shopify_orders
    Shopify::Orders.new(self)
  end
end
```

#### Step 2: Create the Service Class

```ruby
# app/models/shopify/orders.rb
class Shopify::Orders
  def initialize(shop)
    @shop = shop
  end

  def in_batches(of:, after: nil, &block)
    enum = GetOrdersQuery.enumerator(limit: of, after: after)
    return enum.each(&block) if block_given?
    enum
  end

  def import!(api_orders)
    order_records = api_orders.map { |api_order|
      {
        shopify_uuid: GlobalID.parse(api_order.id).model_id,
        order_number: api_order.name,
        total: api_order.total_price
      }
    }

    @shop.orders.upsert_all(
      order_records,
      record_timestamps: true,
      update_only: %i[total],
      unique_by: %i[shop_id shopify_uuid]
    )
  end
end
```

#### Step 3: Create the GraphQL Query

```ruby
# app/graphql/get_orders_query.rb
class GetOrdersQuery
  def self.enumerator(limit:, after: nil)
    ShopifyGraphql::QueryEnumerator.new(
      ORDERS_QUERY,
      dig: [:orders],
      variables: { limit: limit, after: after }
    )
  end

  ORDERS_QUERY = <<~GRAPHQL
    query GetOrders($limit: Int!, $after: String) {
      orders(first: $limit, after: $after) {
        nodes {
          id
          name
          totalPriceSet {
            shopMoney {
              amount
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  GRAPHQL
end
```

#### Step 4: Create the Sync Job

```ruby
# app/jobs/shopify/sync_orders_job.rb
require "active_job/continuable"

class Shopify::SyncOrdersJob < ApplicationJob
  include ShopifySession
  include ActiveJob::Continuable

  def perform(shop:)
    step :process do |step|
      shop.shopify_orders.in_batches(of: 25, after: step.cursor) do |records, cursor|
        shop.shopify_orders.import!(records)
        step.set! cursor
      end
    end
  end
end
```

#### Step 5: Create Webhook Jobs

```ruby
# app/jobs/shopify/webhooks/orders_create_job.rb
class Shopify::Webhooks::OrdersCreateJob < ApplicationJob
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by!(shopify_domain: shop_domain)
    
    shop.orders.create!(
      shopify_uuid: webhook["id"].to_s,
      order_number: webhook["name"],
      total: webhook["total_price"]
    )
  end
end
```

#### Step 6: Update Shop Model

```ruby
# app/models/shop.rb
class Shop < ApplicationRecord
  include Shopify::Collectionable
  include Shopify::Productable
  include Shopify::Orderable  # Add this
  # ...
end
```

#### Step 7: Trigger Sync on Installation

```ruby
# app/jobs/shopify/after_authenticate_job.rb
class Shopify::AfterAuthenticateJob < ApplicationJob
  def perform(shop_domain:)
    shop = Shop.find_by!(shopify_domain: shop_domain)

    Shopify::SyncCollectionsJob.perform_later(shop: shop)
    Shopify::SyncProductsJob.perform_later(shop: shop)
    Shopify::SyncOrdersJob.perform_later(shop: shop)  # Add this
  end
end
```

#### Step 8: Configure Webhooks

```ruby
# config/initializers/shopify_app.rb
# Register webhook topics
```

```ruby
# config/routes.rb
namespace :shopify do
  namespace :webhooks do
    post "orders_create", to: "orders_create#receive"
  end
end
```

## Best Practices

### 1. Always Use Bulk Operations

```ruby
# Good: Bulk upsert
@shop.products.upsert_all(records, unique_by: [:shop_id, :shopify_uuid])

# Bad: N+1 queries
records.each { |r| @shop.products.create!(r) }
```

### 2. Handle Nested Resources Efficiently

```ruby
def import!(api_products)
  # First, import parents
  @shop.products.upsert_all(product_records)
  
  # Then, import children in bulk
  api_products.each do |api_product|
    product = @shop.products.find_by(shopify_uuid: ...)
    import_variants!(product, api_product.variants.nodes)
  end
end
```

### 3. Use Soft Deletes

```ruby
# Don't destroy records - you may need the history
product.discard!  # Sets discarded_at timestamp

# Query active records
shop.products.active  # WHERE discarded_at IS NULL
```

### 4. Parse Global IDs Correctly

```ruby
# Shopify IDs are Global IDs: "gid://shopify/Product/123"
shopify_uuid: GlobalID.parse(api_product.id).model_id  # => "123"
```

### 5. Include ShopifySession in Jobs

```ruby
class MyJob < ApplicationJob
  include ShopifySession  # Automatically activates Shopify session
  
  def perform(shop:)
    # ShopifyAPI calls work here
  end
end
```

## GraphQL Client Features

### Query Enumerator

The `ShopifyGraphql::QueryEnumerator` provides:

- **Lazy evaluation**: Data is fetched as you iterate
- **Automatic pagination**: Handles Shopify's cursor-based pagination
- **Error handling**: Retries on network errors, handles throttling
- **Instrumentation**: Tracks API performance

```ruby
# Fetches 25 at a time, automatically handles pagination
GetProductsQuery.enumerator(limit: 25).each do |products, cursor|
  process_batch(products)
  # cursor available for resumability
end
```

### Error Handling

The client handles:
- Network timeouts and connection errors
- Shopify rate limiting (429 responses)
- Server errors (5xx responses)
- Parallel request conflicts

## Monitoring

All GraphQL requests emit ActiveSupport notifications:

- `shopify_graphql_api.request.success`
- `shopify_graphql_api.request.failed`
- `shopify_graphql_api.request.throttled`
- `shopify_graphql_api.request.connection_error`

Subscribe to these for monitoring:

```ruby
ActiveSupport::Notifications.subscribe("shopify_graphql_api.request.success") do |name, start, finish, id, payload|
  duration = finish - start
  Rails.logger.info("GraphQL request to #{payload[:shop]} took #{duration}s")
end
```

## Resources

- [Shopify GraphQL Admin API](https://shopify.dev/docs/api/admin-graphql)
- [Shopify Webhooks](https://shopify.dev/docs/apps/webhooks)
- [ActiveJob::Continuable](https://github.com/rails/rails/pull/40491) - For resumable jobs
