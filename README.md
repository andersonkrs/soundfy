# Soundfy

A Shopify app for managing digital audio products and recordings.

## Setup

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
```

## Development

```bash
# Start the development server
bin/dev

# Or use Shopify CLI
shopify app dev
```

## Code Quality

```bash
# Ruby linting/formatting
bin/standardrb              # Check all files
bin/standardrb --fix        # Auto-fix issues

# Security scanning
bundle exec brakeman        # Security vulnerability scan
bundle exec bundler-audit   # Check for vulnerable gems
```

## Testing

```bash
bin/rails test              # Run all tests
bin/rails test test/models  # Run model tests
```

## Git Hooks

This project includes a pre-commit hook that automatically runs Standard (Ruby linter/formatter) on staged Ruby files.

To install the hook:
```bash
./script/install-hooks
```

The hook will:
- Run `bin/standardrb --fix --force-exclusion` on staged Ruby files
- Automatically fix formatting issues
- Re-stage fixed files
- Prevent commits if there are unfixable issues

## Documentation

For detailed documentation, see [CURSOR.md](CURSOR.md).
