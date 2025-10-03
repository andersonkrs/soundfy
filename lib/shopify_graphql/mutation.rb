module ShopifyGraphql::Mutation
  extend ShopifyGraphql::Query

  private

  def execute(query, dig: nil, variables: {})
    data = super(query, variables: variables)

    if dig
      result = data.send(*dig)

      user_errors = result.user_errors
      raise APIUserError, user_errors if user_errors.any?

      result
    else
      data
    end
  end
end
