# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Soundfy** is a Shopify app built to help music stores manage digital audio products and recordings. The app allows merchants to associate audio recordings (singles, albums, and tracks) with their Shopify products and variants.

### Tech Stack
- **Backend**: Rails 8.1 (beta) with Ruby 3.4.6
- **Frontend**: React 18 with Inertia.js for server-driven SPAs
- **Database**: PostgreSQL with multiple schemas (primary, cable, cache, queue)
- **UI Framework**: Shopify Polaris for consistent Shopify admin UI
- **Build Tools**: Vite for fast frontend bundling and HMR
- **Background Jobs**: Solid Queue for asynchronous processing
- **Caching**: Solid Cache for Rails caching
- **WebSockets**: Solid Cable for Action Cable
- **Deployment**: Kamal for containerized deployments

## Architecture

### Application Structure

```
soundfy/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── shopify/
│   │       ├── authenticated_controller.rb    # Base for authenticated routes
│   │       ├── home_controller.rb
│   │       └── webhooks/                      # Shopify webhook handlers
│   ├── frontend/
│   │   ├── entrypoints/
│   │   │   ├── application.js                # Main JS entry
│   │   │   ├── inertia.js                    # Inertia setup
│   │   │   └── Layout.jsx                    # App layout with navigation
│   │   └── pages/                            # Inertia page components
│   │       ├── Home.jsx
│   │       └── Admin.jsx
│   ├── jobs/
│   │   ├── concerns/
│   │   │   ├── shop_scoped.rb               # Jobs scoped to a shop
│   │   │   └── shopify_session.rb           # Shopify API session handling
│   │   └── shopify/
│   │       ├── after_authenticate_job.rb    # Post-installation setup
│   │       ├── sync_collections_job.rb
│   │       └── webhooks/                    # Webhook processing jobs
│   ├── models/
│   │   ├── shop.rb                          # Shopify shop session storage
│   │   ├── product.rb                       # Shopify products
│   │   ├── variant.rb                       # Product variants
│   │   ├── recording.rb                     # Polymorphic audio recordings
│   │   ├── single_track.rb                  # Single track recordings
│   │   ├── album.rb                         # Album recordings
│   │   ├── album_track.rb                   # Individual tracks in albums
│   │   └── concerns/
│   │       └── recordable.rb                # Shared recording behavior
│   └── views/
│       └── layouts/
│           └── embedded_app.html.erb        # Shopify embedded app layout
├── config/
│   ├── initializers/
│   │   ├── shopify_app.rb                   # Shopify app configuration
│   │   └── inertia_rails.rb                 # Inertia.js configuration
│   └── routes.rb
├── db/
│   ├── migrate/                             # Database migrations
│   ├── schema.rb                            # Primary database schema
│   ├── cache_schema.rb                      # Solid Cache schema
│   └── queue_schema.rb                      # Solid Queue schema
└── lib/
    └── shopify_graphql/                     # GraphQL query helpers
```

### Domain Model

The app uses Single Table Inheritance (STI) and polymorphic associations to handle different types of audio recordings:

#### Core Entities

**Shop**
- Stores Shopify OAuth session and access token
- Implements `ShopifyApp::ShopSessionStorageWithScopes`
- All other entities are scoped to a shop for multi-tenancy

**Product** → **Variant** (STI base class)
- Mirrors Shopify's product/variant structure
- Synced from Shopify via webhooks
- Uses `shopify_uuid` for Shopify GID mapping
- Soft-deleted with `discarded_at` timestamp
- Base class for Single Table Inheritance (variants table)
- Check constraint: `type` must be NULL or 'Recording'

**Recording** (inherits from Variant via STI)
- Represents a variant that has audio content
- Uses STI: `type = 'Recording'` in variants table
- Polymorphically belongs to a recordable (SingleTrack, Album, or AlbumTrack)
- Can be archived with `archived_at` timestamp
- Enforces one active recording per variant per shop
- Inherits all Variant attributes (title, shopify_uuid, product_id, etc.)
- Check constraint: `recordable_type` must be NULL or one of: 'SingleTrack', 'Album', 'AlbumTrack'

#### Recording Types (Recordables)

**SingleTrack**
- Simplest recordable type
- One track = one recording variant

**Album**
- Container for multiple tracks
- Has its own recording variant (the album itself)
- Contains multiple AlbumTracks via `album_tracks` join table

**AlbumTrack**
- Individual track within an album
- Each AlbumTrack is a recordable with its own Recording variant
- Links to parent Album
- Ordered by `position` within the album

#### Key Relationships

```ruby
# STI with polymorphic associations
Variant (STI base, variants table)
├── Regular Variants (type: nil)
└── Recording (type: 'Recording', inherits from Variant)
    ├── belongs_to :recordable (polymorphic)
    │   ├── SingleTrack
    │   ├── Album
    │   └── AlbumTrack
    └── belongs_to :product (inherited from Variant)

# Album structure
Album (recordable)
├── has_one :recording (the album variant)
└── has_many :album_tracks
    └── each AlbumTrack
        ├── has_one :recording (individual track variant)
        └── belongs_to :album

# Shopify product mapping
Shop
└── Product
    ├── Variant (regular product variants, type: nil)
    └── Recording (audio variants, type: 'Recording')
        └── Recordable (SingleTrack, Album, or AlbumTrack)
```

### Frontend Architecture

The app uses **Inertia.js** to create a single-page application experience without building a separate API:

1. **Server-Side Routing**: Controllers render Inertia pages instead of traditional views
2. **React Components**: Pages are React components in `app/frontend/pages/`
3. **Props from Rails**: Data passed from controllers to React as props
4. **Shopify Polaris**: UI components for consistent Shopify admin experience
5. **App Bridge**: Embedded app features like navigation and toasts

#### Creating New Pages

```ruby
# Controller
class Shopify::WarrantiesController < Shopify::AuthenticatedController
  def index
    render inertia: "Warranties", props: {
      warranties: current_shop.warranties
    }
  end
end
```

```jsx
// app/frontend/pages/Warranties.jsx
import { AppProvider, Page, Card } from "@shopify/polaris";
import enTranslations from "@shopify/polaris/locales/en.json";

export default function Warranties({ warranties }) {
  return (
    <AppProvider i18n={enTranslations}>
      <Page title="Warranties">
        {/* Your component code */}
      </Page>
    </AppProvider>
  );
}
```

### Authentication & Authorization

**Shopify OAuth Flow**
- Handled automatically by `shopify_app` gem
- Session stored in `Shop` model
- JWT-based session verification for embedded apps

**Controller Concerns**
- `ShopifyApp::EmbeddedApp` - App Bridge integration
- `ShopifyApp::EnsureInstalled` - Redirects to OAuth if not installed
- `ShopifyApp::ShopAccessScopesVerification` - Validates API scopes

**Current Shop Pattern**
```ruby
# Set in Shopify::AuthenticatedController
Current.shop = Shop.find_by(shopify_domain: jwt_shopify_domain)
```

### Background Jobs

**Job Concerns**

`ShopifySession` - Wraps job execution with Shopify API session:
```ruby
class MyJob < ApplicationJob
  include ShopifySession

  def perform(shop:)
    # shop.activate_api_session is called automatically
    # Shopify API calls work within this block
  end
end
```

**Common Jobs**
- `Shopify::AfterAuthenticateJob` - Runs after shop installation, triggers product and collection sync
- `Shopify::SyncCollectionsJob` - Syncs collections from Shopify using GraphQL
- `Shopify::SyncProductsJob` - Syncs products and variants from Shopify using GraphQL
- Webhook jobs - Process incoming Shopify webhooks for real-time updates

### Webhooks

Configured in `config/initializers/shopify_app.rb` and registered automatically.

**Mandatory Webhooks** (GDPR compliance)
- `app/uninstalled` - Marks shop as uninstalled
- `customers/data_request` - GDPR data request
- `customers/redact` - GDPR data deletion
- `shop/redact` - GDPR shop data deletion

**App Webhooks**
- `products/create` - Product creation (creates products and variants)
- `products/update` - Product and variant updates (updates products and variants)
- `products/delete` - Product deletion (soft-deletes products)
- `collections/create|update|delete` - Collection changes

### GraphQL Integration

The app uses a custom GraphQL client (`lib/shopify_graphql/`) for efficient batch operations with pagination.

**Query Pattern:**

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

**Shopify Data Sync Pattern:**

Each Shopify resource follows this pattern:

1. **Concern** (`Shopify::Productable`) - Adds association and helper method to Shop
2. **Service Class** (`Shopify::Products`) - Handles batch fetching and importing
3. **GraphQL Query** (`GetProductsQuery`) - Defines the data to fetch
4. **Sync Job** (`Shopify::SyncProductsJob`) - Background job for full sync
5. **Webhook Jobs** - Real-time updates for individual changes

**Example: Products Sync**

```ruby
# 1. Concern (app/models/shopify/productable.rb)
module Shopify::Productable
  extend ActiveSupport::Concern
  
  included do
    has_many :products, dependent: :destroy
  end
  
  def shopify_products
    Shopify::Products.new(self)
  end
end

# 2. Service class (app/models/shopify/products.rb)
class Shopify::Products
  def initialize(shop)
    @shop = shop
  end
  
  def in_batches(of:, after: nil, &block)
    enum = GetProductsQuery.enumerator(limit: of, after: after)
    enum.each(&block)
  end
  
  def import!(api_products)
    # Bulk upsert logic
    @shop.products.upsert_all(records, unique_by: [:shop_id, :shopify_uuid])
  end
end

# 3. Usage in jobs
shop.shopify_products.in_batches(of: 25) do |products, cursor|
  shop.shopify_products.import!(products)
end
```

## Development Workflow

### Prerequisites

- Ruby 3.4.6
- Node.js >=22.0.0
- PostgreSQL
- [Shopify CLI](https://shopify.dev/docs/apps/tools/cli) for app development
- [mise](https://mise.jdx.dev/) (optional, for version management)

### Setup

```bash
# Install dependencies
bundle install
npm install

# Setup database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# Install git hooks (optional but recommended)
./script/install-hooks

# Configure Shopify credentials
bin/rails credentials:edit
# Add:
# shopify:
#   api_key: your_api_key
#   api_secret: your_api_secret
#   app_host: your_app_host
```

### Running the App

**Option 1: Local Development with bin/dev**
```bash
bin/dev                     # Starts Rails server + Vite
# OR with specific port
PORT=3000 bin/dev
```

**Option 2: Shopify CLI (Recommended)**
```bash
shopify app dev            # Auto-configures tunnel and opens app
```

The `bin/dev` script uses:
- Overmind (preferred)
- Hivemind (fallback)
- Foreman (final fallback)

### Database Commands

```bash
# Development database
bin/rails db:create         # Create all databases
bin/rails db:migrate        # Run pending migrations
bin/rails db:seed           # Seed with sample data
bin/rails db:reset          # Drop, create, migrate, seed

# Rollback
bin/rails db:rollback       # Rollback last migration
bin/rails db:rollback STEP=3  # Rollback last 3 migrations

# Console
bin/rails console           # Rails console with loaded app
```

### Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/recording_test.rb

# Run specific test
bin/rails test test/models/recording_test.rb:10
```

### Code Quality

```bash
# Ruby linting/formatting (Standard)
bin/standardrb              # Check all files
bin/standardrb --fix        # Auto-fix issues

# The pre-commit hook automatically runs Standard on staged files
# Install it with: ./script/install-hooks

# Security scanning
bundle exec brakeman        # Security vulnerability scan
bundle exec bundler-audit   # Check for vulnerable gems
```

### Frontend Development

```bash
# Vite runs automatically with bin/dev
# Access at http://localhost:5173 (proxied through Rails)

# Manual Vite commands
bin/vite dev               # Development server
bin/vite build             # Production build
bin/vite clobber           # Clear Vite cache
```

## Common Patterns

### Multi-Tenancy (Shop Scoping)

All data is scoped to shops for multi-tenancy:

```ruby
# Always scope queries to current shop
Current.shop.products.where(...)

# In models with shop_id
belongs_to :shop
validates :shop_id, presence: true

# In concerns
module ShopScoped
  extend ActiveSupport::Concern
  
  included do
    belongs_to :shop
    validates :shop_id, presence: true
  end
end
```

### STI Recordings with Polymorphic Associations

When working with recordings (which inherit from Variant via STI):

```ruby
# Create a single track recording
single = SingleTrack.create!(shop: shop)
recording = Recording.create!(
  shop: shop,
  product: product,
  shopify_uuid: "gid://shopify/ProductVariant/123",
  title: "My Track",
  recordable: single,
  duration_seconds: 180
)

# The recording IS a variant
recording.is_a?(Variant)  # => true
recording.type            # => "Recording"

# Create an album with tracks
album = Album.create!(shop: shop)
album_recording = Recording.create!(
  shop: shop,
  product: album_product,
  shopify_uuid: "gid://shopify/ProductVariant/456",
  title: "My Album",
  recordable: album
)

# Add tracks to the album
track1 = AlbumTrack.create!(
  shop: shop,
  album: album,
  position: 1
)
track1_recording = Recording.create!(
  shop: shop,
  product: album_product,
  shopify_uuid: "gid://shopify/ProductVariant/457",
  title: "Track 1",
  recordable: track1
)

# Access album tracks through the album
album.album_tracks        # Ordered by position
album.tracks              # Recording variants for each track

# Query recordings by type
Recording.singles         # SingleTrack recordings
Recording.albums          # Album recordings
Recording.tracks          # AlbumTrack recordings

# Query all recordings for a product
product.recordings        # All Recording variants
product.variants.regular  # Regular (non-Recording) variants
```

### Archiving vs Soft Deleting

- **Products/Variants**: Use `discarded_at` (soft delete)
- **Recordings**: Use `archived_at` (archival with potential restore)

```ruby
# Archive a recording
recording.archive!     # Sets archived_at to current time
recording.archived?    # => true

# Unarchive
recording.unarchive!   # Sets archived_at to nil

# Query active recordings
Recording.active       # where(archived_at: nil)
```

### Shopify API Sessions

```ruby
# In controllers (automatic via ShopifyApp concerns)
Current.shop.activate_api_session

# In jobs (automatic via ShopifySession concern)
class MyJob < ApplicationJob
  include ShopifySession
  
  def perform(shop:)
    # Session is active here
  end
end

# Manual session activation
shop.activate_api_session do
  # Make Shopify API calls
  ShopifyAPI::Product.all
end
```

## Configuration Files

### Key Configuration

**Shopify App** (`config/initializers/shopify_app.rb`)
- Application name, scope, API version
- Embedded app settings
- Webhook registrations
- After-install job

**Inertia.js** (`config/initializers/inertia_rails.rb`)
- Version management with Vite digest
- Encrypted history for security
- Error handling

**Vite** (`vite.config.ts`)
- React plugin for JSX support
- Ruby plugin for Rails integration

**Shopify CLI** (`shopify.app.development.toml`, `shopify.app.production.toml`)
- Client ID, scopes, webhooks
- Redirect URLs for OAuth
- Dev store configuration

### Environment Variables

Managed via Rails credentials:
```bash
bin/rails credentials:edit            # Edit development credentials
bin/rails credentials:edit --environment production  # Edit production credentials
```

Required credentials:
```yaml
shopify:
  api_key: xxx
  api_secret: xxx
  app_host: https://your-app-url.com
```

## Best Practices

### When Creating Models

1. **Always scope to shop** for multi-tenancy
2. **Use concerns** for shared behavior (`Recordable`, `ShopScoped`)
3. **Validate cross-shop references** to prevent data leaks
4. **Add proper indexes** for foreign keys and unique constraints

### When Creating Controllers

1. **Inherit from `Shopify::AuthenticatedController`** for authenticated routes
2. **Set `Current.shop`** for request context
3. **Use Inertia** (`render inertia: "PageName"`) instead of views
4. **Pass minimal props** to React components

### When Creating Jobs

1. **Include `ShopifySession`** for jobs using Shopify API
2. **Pass `shop:` as keyword argument** for session activation
3. **Use `perform_later`** for async execution
4. **Handle failures gracefully** with retries

### When Writing Migrations

1. **Use safe-pg-migrations gem** for zero-downtime migrations
2. **Add indexes** for all foreign keys
3. **Add constraints** at database level (check constraints, foreign keys, etc.)
4. **Use `null: false`** where appropriate
5. **Add check constraints** for enums and restricted values to ensure data integrity

### When Adding Frontend Pages

1. **Create React component** in `app/frontend/pages/`
2. **Use Shopify Polaris components** for consistent UI
3. **Include `AppProvider`** with translations
4. **Update `Layout.jsx`** if adding navigation items
5. **Test embedded app behavior** in Shopify admin

## Troubleshooting

### Common Issues

**App won't load in Shopify admin**
- Check that `embedded = true` in `shopify.app.*.toml`
- Verify App Bridge is correctly initialized
- Check CORS settings if using custom domain

**Webhooks not processing**
- Verify webhook registration: `ShopifyApp::WebhooksManager.add_registrations`
- Check webhook job is queued in Mission Control
- Verify HMAC validation isn't failing

**Inertia version mismatch errors**
- Clear browser cache
- Restart Vite dev server
- Check `config.version = ViteRuby.digest` in inertia_rails.rb

**Database connection errors**
- Check `config/database.yml` configuration
- Verify PostgreSQL is running
- Ensure all schemas are migrated: `bin/rails db:migrate`

## Testing

### Test Structure

```ruby
# test/models/recording_test.rb
require "test_helper"

class RecordingTest < ActiveSupport::TestCase
  setup do
    @shop = shops(:one)
    @product = products(:one)
    @variant = variants(:one)
  end

  test "should create single track recording" do
    single = SingleTrack.create!(shop: @shop)
    recording = Recording.new(
      shop: @shop,
      product: @product,
      variant: @variant,
      recordable: single
    )
    
    assert recording.save
    assert_equal "SingleTrack", recording.recordable_type
  end
end
```

### Fixtures

Create fixtures in `test/fixtures/` for test data:
```yaml
# test/fixtures/shops.yml
one:
  shopify_domain: "test-shop.myshopify.com"
  shopify_token: "test-token"
  access_scopes: "write_products"
```

## Mission Control

Background jobs can be monitored at `/admin/jobs` using Mission Control::Jobs.

Access the admin interface:
```ruby
# config/routes.rb
namespace :admin do
  mount MissionControl::Jobs::Engine, at: "/jobs"
end
```

## Deployment

The app is configured for deployment with Kamal:

```bash
# Deploy to production
kamal deploy

# Other Kamal commands
kamal setup              # Initial server setup
kamal app logs           # View application logs
kamal app restart        # Restart the app
```

Configuration in `config/deploy.yml`.

## Additional Resources

- [Rails 8 Guides](https://guides.rubyonrails.org/)
- [Shopify App Development](https://shopify.dev/docs/apps)
- [Inertia.js Documentation](https://inertiajs.com/)
- [Shopify Polaris Components](https://polaris.shopify.com/)
- [Vite Rails](https://vite-ruby.netlify.app/)

## Notes for AI Assistants

- **Always scope to shops**: All data must be scoped to prevent cross-shop data leaks
- **Use Inertia, not API endpoints**: Controllers render Inertia pages, not JSON
- **Prefer concerns**: Extract shared behavior into concerns rather than inheritance
- **Validate Shopify UUIDs**: Use `shopify_uuid` for Shopify GID mapping, not integer IDs
- **Test embedded app context**: Features should work in Shopify admin iframe
- **STI Architecture**: Recording inherits from Variant using Single Table Inheritance
  - Regular variants have `type: nil`
  - Recording variants have `type: 'Recording'`
  - All variant attributes are inherited by Recording
  - Check constraint: `type` must be NULL or 'Recording'
- **Polymorphic Recordables**: Recording types use polymorphic associations via `recordable`
  - SingleTrack, Album, and AlbumTrack are recordable types
  - Each has its own table with shop_id
  - Check constraint: `recordable_type` must be NULL or 'SingleTrack', 'Album', 'AlbumTrack'
- **Handle archival correctly**: Recordings can be archived and restored, use `archived?` checks
- **Use delegated types**: Recording uses `delegated_type` for type-specific behavior
- **Variant scopes**: Use `Variant.regular` for non-Recording variants, or query by type
- **Database constraints**: Both `type` and `recordable_type` have check constraints for data integrity
