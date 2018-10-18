module ApiAuth
  # :nodoc:
  class ApiAuthError < StandardError; end

  # Raised when the HTTP request object passed is not supported
  class UnknownHTTPRequest < ApiAuthError; end

  # Raised when the client request digest is not the same as the server
  class InvalidRequestDigest < ApiAuthError; end
end
