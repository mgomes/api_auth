# encoding: UTF-8
# api-auth is a Ruby gem designed to be used both in your client and server
# HTTP-based applications. It implements the same authentication methods (HMAC)
# used by Amazon Web Services.

# The gem will sign your requests on the client side and authenticate that
# signature on the server side. If your server resources are implemented as a
# Rails ActiveResource, it will integrate with that. It will even generate the
# secret keys necessary for your clients to sign their requests.
require 'openssl'
require 'base64'
require 'forwardable'

require 'api_auth/errors'
require 'api_auth/helpers'

require 'api_auth/request_drivers/base'
require 'api_auth/request_drivers/net_http'
require 'api_auth/request_drivers/curb'
require 'api_auth/request_drivers/rest_client'
require 'api_auth/request_drivers/action_controller'
require 'api_auth/request_drivers/action_dispatch'
require 'api_auth/request_drivers/rack'
require 'api_auth/request_drivers/httpi'

require 'api_auth/headers'

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
      headers.set_content_md5
      headers.set_date
      headers.set_auth_header auth_header(request, access_id, secret_key)
    end

    # Determines if the request is authentic given the request and the client's
    # secret key. Returns true if the request is authentic and false otherwise.
    def authentic?(request, secret_key)
      return false if secret_key.nil?

      return md5_match?(request) && signatures_match?(request, secret_key) && valid_request?(request)
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

    def valid_request?(request)
      headers = Headers.new(request)
      begin
        Time.httpdate(headers.timestamp).utc > (Time.now.utc - 15.minutes)
      rescue ArgumentError
        false
      end
    end

    def md5_match?(request)
      headers = Headers.new(request)
      headers.md5_match?
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
      Regexp.new('APIAuth ([^:]+):(.+)$').match(auth_header)
    end

  end # class methods

end # ApiAuth

require 'api_auth/railtie'
