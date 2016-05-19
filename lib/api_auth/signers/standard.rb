require 'api_auth/helpers'

module ApiAuth
  module Signers
    class Standard # :nodoc:
      class << self
        include Helpers

        def sign(headers, secret_key, options)
          canonical_string = headers.canonical_string(options[:override_http_method])
          digest = OpenSSL::Digest.new(options[:digest])
          b64_encode(OpenSSL::HMAC.digest(digest, secret_key, canonical_string))
        end
      end
    end
  end
end
