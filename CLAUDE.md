# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Shopify app built with Rails 8.1 (beta), React, and Inertia.js. The app uses Vite for frontend bundling and is configured to run as an embedded Shopify app.

## Development Commands

### Starting the Development Server
```bash
bin/dev                    # Starts Rails server and Vite dev server
# or
shopify app dev            # Run through Shopify CLI for app development
```

### Database Management
```bash
bin/rails db:create        # Create all databases
bin/rails db:migrate       # Run migrations
bin/rails db:seed          # Seed the database
bin/rails db:reset         # Drop, create, migrate, and seed
```

### Running Tests
```bash
bin/rails test             # Run all tests
bin/rails test test/path  # Run specific test file
```

### Code Quality
```bash
bundle exec standardrb     # Run Ruby linter
bundle exec brakeman       # Security analysis
```

### Console Access
```bash
bin/rails console          # Rails console
bin/rails c                # Short version
```

## Architecture

### Backend Structure
- **Rails 8.1** with PostgreSQL database
- **Authentication**: ShopifyApp gem handles OAuth and session management
- **Base Controllers**:
  - `AuthenticatedController` - For routes requiring Shopify session
  - Controllers including `ShopifyApp::EmbeddedApp` - For embedded app pages
- **API Configuration**: Shopify API version 2025-07
- **Background Jobs**: Using Solid Queue for job processing
- **Caching**: Solid Cache for Rails caching
- **WebSockets**: Solid Cable for Action Cable

### Frontend Structure
- **Inertia.js** bridges Rails and React without API endpoints
- **React Components**: Located in `app/frontend/pages/`
- **Entry Points**: `app/frontend/entrypoints/`
- **Vite** handles bundling and HMR
- **Shopify Polaris** for UI components

### Key Configuration Files
- `config/initializers/shopify_app.rb` - Shopify app configuration
- `shopify.app.toml` - Shopify CLI configuration
- `vite.config.ts` - Vite bundler configuration
- `config/initializers/inertia_rails.rb` - Inertia.js configuration

### Shopify Integration
- **Webhooks**: Configured for app/uninstalled, customers/data_request, customers/redact, shop/redact
- **Embedded App**: Runs inside Shopify admin interface
- **Session Storage**: Shop model stores Shopify session data
- **Scopes**: Currently configured with `write_products`

### Credentials Management
Shopify API credentials are stored in Rails encrypted credentials:
- `shopify.api_key`
- `shopify.api_secret`
- `shopify.app_host`

Access with: `bin/rails credentials:edit`

## Development Workflow

1. Controllers render Inertia pages instead of traditional Rails views
2. Inertia pages are React components in `app/frontend/pages/`
3. Props are passed from Rails controllers to React components
4. Vite provides hot module replacement for rapid development
5. Shopify app runs embedded in the Shopify admin

### Inertia.js Conventions

**IMPORTANT**: When passing props from Rails controllers to React components via Inertia.js:
- **Always use snake_case** for property names (Ruby convention)
- **DO NOT camelize** property names (e.g., use `created_at` not `createdAt`)
- React components should access props using snake_case (e.g., `recording.product_id`)
- **Use Jbuilder templates** to render props instead of manually mapping in controllers

#### Using Jbuilder Templates with Inertia.js

Create a Jbuilder template with the same path as your Inertia view:

**Controller** (`app/controllers/shopify/recordings_controller.rb`):
```ruby
class Shopify::RecordingsController < Shopify::AuthenticatedController
  def index
    @recordings = Current.shop.recordings.active
    render inertia: "Recordings/Index"
  end
end
```

**Jbuilder Template** (`app/views/shopify/recordings/index.json.jbuilder`):
```ruby
json.recordings @recordings do |recording|
  json.id recording.id
  json.product_id recording.product_id
  json.product_title recording.product&.title
  json.created_at recording.created_at.iso8601
end
```

**React Component** (`app/frontend/pages/Recordings/Index.jsx`):
```jsx
export default function RecordingsIndex({ recordings }) {
  // Access props using snake_case
  recordings.map(r => r.product_id)
}
```

Benefits of Jbuilder templates:
- Cleaner controllers (separation of concerns)
- Reusable JSON structure
- Easier to maintain and test
- Consistent API responses

## Important Notes

- Always ensure proper Shopify session verification in controllers
- Use `AuthenticatedController` for routes that require merchant authentication
- Frontend assets are served by Vite in development
- Database uses multiple schemas: primary, cable, cache, queue
