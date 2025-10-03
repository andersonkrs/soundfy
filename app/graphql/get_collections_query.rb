class GetCollectionsQuery
  def self.enumerator(limit:, search: nil, after: nil)
    ShopifyGraphql::QueryEnumerator.new(
      COLLECTIONS_QUERY,
      dig: [ :collections ],
      variables: {
        limit: limit,
        after: after,
        query: search
      }
    )
  end

  COLLECTIONS_QUERY = <<~GRAPHQL
    query GetCollections($limit: Int!, $after: String, $query: String) {
      collections(first: $limit, after: $after, query: $query) {
        nodes {
          id
          title
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  GRAPHQL
end
