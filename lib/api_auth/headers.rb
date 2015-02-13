module ApiAuth

  # Builds the canonical string given a request object.
  class Headers

    extend Forwardable
    include RequestDrivers

    def_delegators :@request, :timestamp, :authorization_header, :set_content_md5,
                              :set_date, :md5_match?, :set_auth_header

    def initialize(request)
      @original_request = request
      @request = RequestDrivers::Base.initialize_appropiate_driver(request)
      true
    end

    # Returns the canonical string computed from the request's headers
    def canonical_string
      [ @request.content_type,
        @request.content_md5,
        @request.request_uri.gsub(/https?:\/\/[^(,|\?|\/)]*/,''), # remove host
        @request.timestamp
      ].join(",")
    end

  end

end
