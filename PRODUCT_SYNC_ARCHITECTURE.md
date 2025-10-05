# Product Sync Architecture

This document describes the product synchronization system built for Soundfy, following the same pattern as the Collections sync system.

## Overview

The product sync system fetches products and variants from Shopify using GraphQL and keeps them synchronized via webhooks.

## Architecture Components

### 1. Concern: `Shopify::Productable`

**Location**: `app/models/shopify/productable.rb`

Adds product synchronization capabilities to the Shop model.

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

**Usage**:
```ruby
shop.shopify_products.in_batches(of: 25) do |products|
  # Process products
end
```

### 2. Service Class: `Shopify::Products`

**Location**: `app/models/shopify/products.rb`

Handles product import logic with batch processing support.

**Key Methods**:

- `in_batches(of:, after:)` - Paginates through products using GraphQL cursor
- `import!(api_products)` - Upserts products and variants
- `import_variants!(product, api_variants)` - (private) Upserts variants for a product

**Features**:
- Atomic upserts for products and variants
- Handles nested variant imports
- Uses `upsert_all` for performance
- Updates `title` field, preserves `discarded_at` status

### 3. GraphQL Query: `GetProductsQuery`

**Location**: `app/graphql/get_products_query.rb`

Queries Shopify's GraphQL Admin API for products and their variants.

**Query Structure**:
```graphql
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
```

**Usage**:
```ruby
GetProductsQuery.enumerator(limit: 25, after: cursor)
```

### 4. Background Job: `Shopify::SyncProductsJob`

**Location**: `app/jobs/shopify/sync_products_job.rb`

Performs bulk product synchronization from Shopify.

**Includes**:
- `ShopifySession` - Automatic Shopify API session management
- `ActiveJob::Continuable` - Resumable job execution with cursor tracking

**Execution Flow**:
1. Fetches products in batches of 25
2. Imports each batch (products + variants)
3. Tracks cursor for resumability
4. Called by `Shopify::AfterAuthenticateJob` after shop installation

### 5. Webhook Controllers

#### `ProductsCreateController`

**Location**: `app/controllers/shopify/webhooks/products_create_controller.rb`

Receives `products/create` webhooks from Shopify when a new product is created.

#### `ProductsUpdateController`

**Location**: `app/controllers/shopify/webhooks/products_update_controller.rb`

Receives `products/update` webhooks from Shopify when a product is modified.

**Features**:
- HMAC verification via `ShopifyApp::WebhookVerification`
- Parses webhook payload using `ShopifyAPI::Webhooks::Request`
- Enqueues job for async processing
- Returns `204 No Content` immediately

### 6. Webhook Jobs

#### `ProductsCreateJob`

**Location**: `app/jobs/shopify/webhooks/products_create_job.rb`

Processes product creation webhooks.

**Includes**: `ShopScoped` - Automatic shop lookup and session setup

**Logic**:
1. Creates product with `shopify_uuid` and `title`
2. Inserts all variants with `insert_all`
3. Logs creation results

#### `ProductsUpdateJob`

**Location**: `app/jobs/shopify/webhooks/products_update_job.rb`

Processes product update webhooks.

**Includes**: `ShopScoped` - Automatic shop lookup and session setup

**Logic**:
1. Finds or creates product by `shopify_uuid`
2. Updates product title
3. Un-discards product if previously deleted
4. Upserts all variants
5. Logs sync results

### 7. Webhook Controller: `ProductsDeleteController`

**Location**: `app/controllers/shopify/webhooks/products_delete_controller.rb`

Receives `products/delete` webhooks from Shopify.

**Pattern**: Same as ProductsUpdateController

### 8. Webhook Job: `ProductsDeleteJob`

**Location**: `app/jobs/shopify/webhooks/products_delete_job.rb`

Soft-deletes products when removed from Shopify.

**Logic**:
1. Finds product by `shopify_uuid`
2. Marks as discarded (soft delete)
3. Logs deletion
4. Handles missing products gracefully

## Data Flow

### Initial Sync (After Shop Installation)

```
Shopify::AfterAuthenticateJob
  └─> Shopify::SyncProductsJob
      └─> shop.shopify_products.in_batches(25)
          └─> GetProductsQuery (GraphQL)
              └─> shop.shopify_products.import!(products)
                  ├─> Product.upsert_all
                  └─> Variant.upsert_all
```

### Real-time Updates (Webhooks)

```
Shopify Webhook: products/create
  └─> ProductsCreateController
      └─> ProductsCreateJob (async)
          ├─> Create Product
          └─> Insert variants
```

```
Shopify Webhook: products/update
  └─> ProductsUpdateController
      └─> ProductsUpdateJob (async)
          ├─> Find/Update Product
          ├─> Update title
          └─> Upsert variants
```

```
Shopify Webhook: products/delete
  └─> ProductsDeleteController
      └─> ProductsDeleteJob (async)
          └─> Product.discard!
```

## Database Schema

### Products Table

```ruby
create_table "products" do |t|
  t.bigint "shop_id", null: false
  t.string "shopify_uuid", null: false    # Shopify GID
  t.string "title"
  t.datetime "discarded_at"                # Soft delete timestamp
  t.timestamps

  index ["shop_id", "shopify_uuid"], unique: true
end
```

### Variants Table (with STI)

```ruby
create_table "variants" do |t|
  t.bigint "shop_id", null: false
  t.bigint "product_id", null: false
  t.string "shopify_uuid", null: false
  t.string "title"
  t.string "type"                         # STI: nil or 'Recording'
  t.datetime "discarded_at"                # Soft delete
  
  # Recording-specific fields
  t.bigint "recordable_id"
  t.string "recordable_type"
  t.integer "duration_seconds"
  t.datetime "archived_at"
  
  t.timestamps

  index ["shop_id", "shopify_uuid"], unique: true
  index ["shop_id", "type"]
  
  check_constraint "type IS NULL OR type = 'Recording'"
  check_constraint "recordable_type IS NULL OR recordable_type IN ('SingleTrack', 'Album', 'AlbumTrack')"
end
```

## Configuration

### Routes

```ruby
namespace :shopify do
  namespace :webhooks do
    post "products_create", to: "products_create#receive"
    post "products_update", to: "products_update#receive"
    post "products_delete", to: "products_delete#receive"
  end
end
```

### Webhook Registration

Webhooks are automatically registered via `config/initializers/shopify_app.rb`:

```ruby
ShopifyApp::WebhooksManager.add_registrations
```

## Model Enhancements

### Product Model

**Location**: `app/models/product.rb`

**New Methods**:
- `discard!` - Soft delete product
- `undiscard!` - Restore discarded product
- `discarded?` - Check if product is discarded

**Scopes**:
- `active` - Non-discarded products
- `discarded` - Soft-deleted products

**Validations**:
- `shopify_uuid` - Present and unique per shop
- `title` - Present

### Variant Model

**Location**: `app/models/variant.rb`

**New Methods**:
- `discard!` - Soft delete variant
- `undiscard!` - Restore discarded variant
- `discarded?` - Check if variant is discarded

**Scopes**:
- `regular` - Non-Recording variants (type: nil)
- `active` - Non-discarded variants
- `discarded` - Soft-deleted variants

**Validations**:
- `shopify_uuid` - Present and unique per shop
- Product must belong to same shop

## Error Handling

### ShopScoped Concern

Automatically handles:
- Shop not found errors
- Shopify API session setup
- Current shop context (`Current.shop`)

### Webhook Jobs

- Gracefully handles missing products
- Logs all operations
- Records not found are logged as warnings
- Failures are retried by ActiveJob

## Performance Considerations

### Batch Processing

- Products synced in batches of 25
- Uses cursor-based pagination
- Resumable via `ActiveJob::Continuable`

### Database Operations

- `upsert_all` for atomic updates
- Bulk inserts reduce database round trips
- Indexed lookups on `shopify_uuid`

### Webhook Processing

- Async job processing prevents webhook timeouts
- Responds immediately with 204 status
- Job retries on failure

## Testing

### Manual Testing

```ruby
# Sync all products
shop = Shop.first
Shopify::SyncProductsJob.perform_now(shop: shop)

# Test webhook processing
webhook_data = {
  'id' => '123456789',
  'title' => 'Test Product',
  'variants' => [
    {'id' => '987654321', 'title' => 'Default'}
  ]
}

Shopify::Webhooks::ProductsUpdateJob.perform_now(
  shop_domain: shop.shopify_domain,
  webhook: webhook_data
)
```

## Comparison with Collections Sync

| Feature | Collections | Products |
|---------|------------|----------|
| Concern | `Shopify::Collectionable` | `Shopify::Productable` |
| Service | `Shopify::Collections` | `Shopify::Products` |
| Query | `GetCollectionsQuery` | `GetProductsQuery` |
| Sync Job | `SyncCollectionsJob` | `SyncProductsJob` |
| Nested Data | No | Yes (variants) |
| Soft Delete | No | Yes (`discarded_at`) |
| Webhooks | create/update/delete | create/update/delete |

## Future Enhancements

1. **Product Image Sync** - Add image URLs to products
2. **Inventory Tracking** - Sync variant inventory levels
3. **Product Status** - Track published/draft status
4. **Metafields** - Sync custom product metadata
5. **Bulk Operations** - Use Shopify's Bulk Query for large catalogs
6. **Variant Options** - Store variant options (size, color, etc.)

## Monitoring

### Mission Control

View job status at `/admin/jobs`:
- `Shopify::SyncProductsJob` - Bulk sync status
- `Shopify::Webhooks::ProductsUpdateJob` - Webhook processing
- `Shopify::Webhooks::ProductsDeleteJob` - Deletion processing

### Logs

```ruby
# Check sync logs
Rails.logger.tagged("ProductSync") do |logger|
  logger.info "Product synced: #{product.shopify_uuid}"
end
```

## Related Documentation

- [CURSOR.md](CURSOR.md) - General development guide
- [CLAUDE.md](CLAUDE.md) - Project overview for Claude
- Shopify GraphQL API: https://shopify.dev/docs/api/admin-graphql
