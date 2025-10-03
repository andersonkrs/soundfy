class ShopifyGraphql::QueryEnumerator
  include ShopifyGraphql::Query

  def initialize(query, dig:, variables: {})
    @query = query
    @variables = variables
    @dig = dig
  end

  def self.new(*args, **kwargs)
    super(*args, **kwargs).to_enum(:each).lazy
  end

  private

  def each
    current_cursor = @variables[:after]

    loop do
      data = execute(@query, variables: @variables.merge(after: current_cursor))

      query_result = data.dig(*@dig)

      current_cursor = query_result&.page_info&.end_cursor

      if query_result&.nodes&.present?
        yield query_result.nodes, query_result.page_info.end_cursor
      end

      break unless query_result&.page_info&.has_next_page
    end
  end
end
