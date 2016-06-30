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
    # Curb (Curl::Easy), RestClient object or Faraday::Request.
    #
    # access_id: The public unique identifier for the client
    #
    # secret_key: assigned secret key that is known to both parties
    def sign!(request, access_id, secret_key, options = {})
      options = { :override_http_method => nil, :digest => 'sha1' }.merge(options)
      headers = Headers.new(request)
      headers.calculate_md5
      headers.set_date
      headers.sign_header auth_header(headers, access_id, secret_key, options)
    end

    # Determines if the request is authentic given the request and the client's
    # secret key. Returns true if the request is authentic and false otherwise.
    def authentic?(request, secret_key, options = {})
      return false if secret_key.nil?

      options = { :override_http_method => nil }.merge(options)

      headers = Headers.new(request)

      if headers.md5_mismatch?
        false
      elsif !signatures_match?(headers, secret_key, options)
        false
      elsif request_too_old?(headers)
        false
      else
        true
      end
    end

    # Returns the access id from the request's authorization header
    def access_id(request)
      headers = Headers.new(request)
      if match_data = parse_auth_header(headers.authorization_header)
        return match_data[2]
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

    def request_too_old?(headers)
      # 900 seconds is 15 minutes

      timestamp = DateTime.strptime(headers.timestamp, ApiAuth.configuration.date_format)
      time = Time.local(timestamp.year, timestamp.month, timestamp.day, timestamp.hour, timestamp.min, timestamp.sec)
      time.utc < (Time.now.utc - 900)
    rescue ArgumentError
      true
    end

    def signatures_match?(headers, secret_key, options)
      match_data = parse_auth_header(headers.authorization_header)
      return false unless match_data

      digest = match_data[1].nil? ? 'SHA1' : match_data[1].upcase
      raise InvalidRequestDigest if !options[:digest].nil? && !options[:digest].casecmp(digest).zero?

      options = { :digest => digest }.merge(options)

      header_sig = match_data[3]
      calculated_sig = hmac_signature(headers, secret_key, options)

      secure_compare(header_sig, calculated_sig)
    end

    def hmac_signature(headers, secret_key, options)
      ApiAuth.configuration.signer.sign(headers, secret_key, options)
    end

    def auth_header(headers, access_id, secret_key, options)
      ApiAuth.configuration.auth_header_factory.auth_header(headers, access_id, options, hmac_signature(headers, secret_key, options))
    end

    def parse_auth_header(auth_header)
      ApiAuth.configuration.auth_header_pattern.match(auth_header)
    end

    # Copy of ActiveSupport::SecurityUtils.secure_compare from Rails 4.2.0
    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end # class methods
end # ApiAuth
