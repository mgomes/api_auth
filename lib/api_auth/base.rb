# encoding: UTF-8
# api-auth is a Ruby gem designed to be used both in your client and server
# HTTP-based applications. It implements the same authentication methods (HMAC)
# used by Amazon Web Services.

# The gem will sign your requests on the client side and authenticate that
# signature on the server side. If your server resources are implemented as a
# Rails ActiveResource, it will integrate with that. It will even generate the
# secret keys necessary for your clients to sign their requests.
module ApiAuth

  class << self

    include Helpers

    # Signs an HTTP request using the client's access id and secret key.
    # Returns the HTTP request object with the modified headers.
    #
    # request: The request can be a Net::HTTP, ActionDispatch::Request,
    # Curb (Curl::Easy) or a RestClient object.
    #
    # access_id: The public unique identifier for the client
    #
    # secret_key: assigned secret key that is known to both parties
    def sign!(request, access_id, secret_key)
      headers = Headers.new(request)
      headers.calculate_md5
      headers.set_date
      headers.sign_header auth_header(request, access_id, secret_key)
    end

    # Determines if the request is authentic given the request and the client's
    # secret key. Returns true if the request is authentic and false otherwise.
    def authentic?(request, secret_key)
      return false if secret_key.nil?

      return !md5_mismatch?(request) && signatures_match?(request, secret_key) && !request_too_old?(request)
    end

    # Returns the access id from the request's authorization header
    def access_id(request)
      headers = Headers.new(request)
      if match_data = parse_auth_header(headers.authorization_header)
        return match_data[1]
      end

      nil
    end

    # Generates a Base64 encoded, randomized secret key
    #
    # Store this key along with the access key that will be used for
    # authenticating the client
    def generate_secret_key
      random_bytes = OpenSSL::Random.random_bytes(512)
      b64_encode(Digest::SHA2.new(512).digest(random_bytes))
    end

  private

    def request_too_old?(request)
      headers = Headers.new(request)
      # 900 seconds is 15 minutes
      begin 
        Time.httpdate(headers.timestamp).utc < (Time.now.utc - 900)
      rescue ArgumentError
        true
      end
    end

    def md5_mismatch?(request)
      headers = Headers.new(request)
      headers.md5_mismatch?
    end

    def signatures_match?(request, secret_key)
      headers = Headers.new(request)
      if match_data = parse_auth_header(headers.authorization_header)
        hmac = match_data[2]
        return hmac == hmac_signature(request, secret_key)
      end
      false
    end

    def hmac_signature(request, secret_key)
      headers = Headers.new(request)
      canonical_string = headers.canonical_string
      digest = OpenSSL::Digest.new('sha1')
      b64_encode(OpenSSL::HMAC.digest(digest, secret_key, canonical_string))
    end

    def auth_header(request, access_id, secret_key)
      "APIAuth #{access_id}:#{hmac_signature(request, secret_key)}"
    end

    def parse_auth_header(auth_header)
      Regexp.new("APIAuth ([^:]+):(.+)$").match(auth_header)
    end

  end # class methods

end # ApiAuth
