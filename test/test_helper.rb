ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "shopify_app/test_helpers/all"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include ShopifyApp test helpers
    include ShopifyApp::TestHelpers::ShopifySessionHelper

    # Add more helper methods to be used by all tests here...
  end
end
