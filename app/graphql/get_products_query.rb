class GetProductsQuery
  def self.enumerator(limit:, search: nil, after: nil, &block)
    ShopifyGraphql::QueryEnumerator.new(
      PRODUCTS_QUERY,
      dig: [:products],
      variables: {
        limit: limit,
        after: after,
        query: search
      },
      &block
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
