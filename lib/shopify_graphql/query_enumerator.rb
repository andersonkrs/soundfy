class ShopifyGraphql::QueryEnumerator
  include ShopifyGraphql::Query

  def initialize(query, dig:, variables: {})
    @query = query
    @variables = variables
    @dig = dig
  end

  def self.new(*args, **kwargs, &block)
    enum = super.to_enum(:each)

    if block_given?
      enum.each(&block)
    else
      enum.lazy
    end
  end

  private

  def each
    current_cursor = @variables[:after]

    loop do
      data = execute(@query, variables: @variables.merge(after: current_cursor))

      query_result = data.dig(*@dig)

      current_cursor = query_result&.page_info&.end_cursor

      yield query_result.nodes.presence || [], current_cursor

      break unless query_result&.page_info&.has_next_page
    end
  end
end
