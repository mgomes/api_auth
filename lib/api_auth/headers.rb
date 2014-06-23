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
        else
          nil
        end

      return new_request if new_request
      return RackRequest.new(request) if request.kind_of?(Rack::Request)
      raise UnknownHTTPRequest, "#{request.class.to_s} is not yet supported."
    end
    private :initialize_request_driver

    # Returns the request timestamp
    def timestamp
       @request.timestamp
    end

    # Returns the canonical string computed from the request's headers
    def canonical_string
      [ @request.content_type,
        @request.content_md5,
        @request.request_uri.gsub(/https?:\/\/[^(,|\?|\/)]*/,''), # remove host
        @request.timestamp
      ].join(",")
    end

    # Returns the authorization header from the request's headers
    def authorization_header
      @request.authorization_header
    end

    def set_date
      @request.set_date if @request.timestamp.empty?
    end

    def calculate_md5
      @request.populate_content_md5 if @request.content_md5.empty?
    end

    def md5_mismatch?
      if @request.content_md5.empty?
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

  end

end
