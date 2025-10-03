module ShopifyGraphql::Query
  extend ActiveSupport::Concern

  private

  def graphql_client
    @graphql_client ||= ShopifyGraphql::Client.new
  end

  def execute(query, variables: {})
    graphql_client.execute(query, variables: variables)
  end
end
