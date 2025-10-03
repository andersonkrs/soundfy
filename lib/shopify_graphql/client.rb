class ShopifyGraphql::Client
  extend ActiveSupport::Concern

  NETWORK_ERRORS = [
    Errno::ECONNRESET,
    Errno::EPIPE,
    Errno::ECONNREFUSED,
    Errno::ENETUNREACH,
    Net::ReadTimeout,
    Net::OpenTimeout,
    OpenSSL::SSL::SSLError,
    EOFError,
    SocketError
  ].freeze

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

  attr_reader :instrumentation_context

  def execute(query, variables: {})
    set_context(query: query, variables: variables)

    response = client.query(query: query, variables: variables)

    handle_response(response.body)

    JSON.parse(
      response.body.deep_transform_keys(&:underscore).to_json,
      object_class: OpenStruct
    ).data
  rescue *NETWORK_ERRORS => e
    ActiveSupport::Notifications.instrument("shopify_graphql_api.request.connection_error", instrumentation_context)
    raise ConnectionError.new(e, "Network error")
  end

  private

  def client
    ShopifyAPI::Clients::Graphql::Admin.new(session: ShopifyAPI::Context.active_session)
  end

  def handle_response(response)
    errors = response.dig("errors")

    if errors.present?
      errors_data = errors.map(&:deep_symbolize_keys)

      case errors_data
      in [ { message: "503 Service Unavailable" }, * ] |
         [ { message: "503 Service Temporarily Unavailable" }, * ] |
         [ { message: "504 Gateway Timeout" }, * ] |
         [ { message: "502 Bad Gateway" }, * ] |
         [ { message: "520 " }, * ] |
         [ { message: "530 " }, * ] |
         [ { message: "500 Internal Server Error" }, * ] => info
        ActiveSupport::Notifications.instrument("shopify_graphql_api.request.connection_error", instrumentation_context)
        raise ConnectionError.new(errors_data, info.dig(0, :message))
      in [ { message: "Throttled" }, * ]
        ActiveSupport::Notifications.instrument("shopify_graphql_api.request.throttled", instrumentation_context)
        raise TooManyRequestsError, errors_data
      else
        ActiveSupport::Notifications.instrument("shopify_graphql_api.request.failed", instrumentation_context)
        handle_api_request_error(errors_data)
      end
    end

    ActiveSupport::Notifications.instrument("shopify_graphql_api.request.success", instrumentation_context)
  end

  def handle_api_request_error(errors)
    case errors
    in [ { extensions: { code: "TOO_MANY_PARALLEL_REQUESTS_FOR_THIS_PRODUCT" } }, * ] => data
      raise EntityLockedError, data
    else
      raise APIRequestError, errors
    end
  end

  def set_context(query:, variables:)
    active_session = ShopifyAPI::Context.active_session
    shopify_domain = active_session&.shop

    @instrumentation_context = { shop: shopify_domain }
    Rails.error.set_context(shop: shopify_domain, graphql_variables: variables.as_json)
  end
end
