module ShopifyGraphql
  class APIError < StandardError; end
  class APIUserError < APIError; end
  class APIRequestError < APIError; end
  class TooManyRequestsError < APIRequestError; end
  class EntityLockedError < APIRequestError; end

  class ConnectionError < APIError
    attr_reader :response

    def initialize(response, message = nil)
      @response = response
      @message = message
      super(@message)
    end

    def to_s
      message = "Failed.".dup
      message << " Response message = #{@message}." if @message
      message
    end
  end
end
