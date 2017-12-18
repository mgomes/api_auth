module ApiAuth
  # Builds the canonical string given a request object.
  class Headers
    include RequestDrivers

    def initialize(request)
      @original_request = request
      @request = initialize_request_driver(request)
      true
    end

    def initialize_request_driver(request)
      new_request =
        case request.class.to_s
        when /Net::HTTP/
          NetHttpRequest.new(request)
        when /RestClient/
          RestClientRequest.new(request)
        when /Curl::Easy/
          CurbRequest.new(request)
        when /ActionController::Request/
          ActionControllerRequest.new(request)
        when /ActionController::TestRequest/
          if defined?(ActionDispatch)
            ActionDispatchRequest.new(request)
          else
            ActionControllerRequest.new(request)
          end
        when /ActionDispatch::Request/
          ActionDispatchRequest.new(request)
        when /ActionController::CgiRequest/
          ActionControllerRequest.new(request)
        when /HTTPI::Request/
          HttpiRequest.new(request)
        when /Faraday::Request/
          FaradayRequest.new(request)
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

    private

    def parse_uri(uri)
      parsed_uri = URI.parse(uri)

      uri_without_host = parsed_uri.respond_to?(:request_uri) ? parsed_uri.request_uri : uri
      return '/' if uri_without_host.empty?
      escape_params(uri_without_host)
    end

    # Different versions of request parsers escape/unescape the param values
    # Examples:
    # Rails 5.1.3 ApiAuth canonical_string:
    #    'GET,application/json,,/api/v1/employees?select=epulse_id%2Cfirst_name%2Clast_name,Thu, 14 Dec 2017 16:19:48 GMT'
    # Rails 5.1.4 ApiAuth canonical_string:
    #    'GET,application/json,,/api/v1/employees?select=epulse_id,first_name,last_name,Thu, 14 Dec 2017 16:20:57 GMT'
    # This will force param values to escaped and fixes issue #123
    def escape_params(uri)
      unescaped_uri = CGI.unescape(uri)
      uri_array = unescaped_uri.split('?')
      return uri unless uri_array.length > 1
      params = uri_array[1].split('&')
      encoded_params = ''
      params.each do |param|
        next unless param.include?('=')
        encoded_params += '&' if encoded_params.length > 0
        split_param = param.split('=')
        encoded_params += split_param[0] + '=' + CGI.escape(split_param[1])
      end
      uri_array[0] + '?' + encoded_params
    end
  end
end
