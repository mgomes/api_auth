module ApiAuth
  # Builds the canonical string given a request object.
  class Headers
    include RequestDrivers

    def initialize(request, configuration = Configuration.new)
      @original_request = request
      @configuration = configuration
      @request = initialize_request_driver(request)
    end

    def initialize_request_driver(request)
      new_request =
        case request.class.to_s
        when /Net::HTTP/
          NetHttpRequest.new(request, @configuration)
        when /RestClient/
          RestClientRequest.new(request, @configuration)
        when /Curl::Easy/
          CurbRequest.new(request, @configuration)
        when /ActionController::Request/
          ActionControllerRequest.new(request, @configuration)
        when /ActionController::TestRequest/
          if defined?(ActionDispatch)
            ActionDispatchRequest.new(request, @configuration)
          else
            ActionControllerRequest.new(request, @configuration)
          end
        when /ActionDispatch::Request/
          ActionDispatchRequest.new(request, @configuration)
        when /ActionController::CgiRequest/
          ActionControllerRequest.new(request, @configuration)
        when /HTTPI::Request/
          HttpiRequest.new(request, @configuration)
        when /Faraday::Request/
          FaradayRequest.new(request, @configuration)
        end

      return new_request if new_request
      return RackRequest.new(request) if request.is_a?(Rack::Request)
      raise UnknownHTTPRequest, "#{request.class} is not yet supported."
    end
    private :initialize_request_driver

    # Returns the request timestamp
    def timestamp
      @request.timestamp
    end

    def parsed_timestamp
      Time.strptime(timestamp, @configuration.date_format)
    end

    def canonical_string(override_method = nil)
      request_method = override_method || @request.http_method

      raise ArgumentError, 'unable to determine the http method from the request, please supply an override' if request_method.nil?

      [request_method.upcase,
       @request.content_type,
       @request.content_md5,
       parse_uri(@request.original_uri || @request.request_uri),
       @request.timestamp].join(',')
    end

    # Returns the authorization header from the request's headers
    def authorization_header
      @request.authorization_header
    end

    def set_date
      @request.set_date if @request.timestamp.nil?
    end

    def calculate_md5
      @request.populate_content_md5 if @request.content_md5.nil?
    end

    def md5_mismatch?
      if @request.content_md5.nil?
        false
      else
        @request.md5_mismatch?
      end
    end

    # Sets the request's authorization header with the passed in value.
    # The header should be the ApiAuth HMAC signature.
    #
    # This will return the original request object with the signed Authorization
    # header already in place.
    def sign_header(header)
      @request.set_auth_header header
    end

    def http_headers
      @request.headers
    end

    private

    def parse_uri(uri)
      parsed_uri = URI.parse(uri)

      return parsed_uri.request_uri if parsed_uri.respond_to?(:request_uri)

      uri.empty? ? '/' : uri
    end
  end
end
