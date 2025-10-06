# frozen_string_literal: true

# Pagy initializer file

# Set global defaults
Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT[:size] = 7

# Freeze the defaults to prevent accidental modifications
Pagy::DEFAULT.freeze
