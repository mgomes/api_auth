module ApiAuth
  
  # :nodoc:
  class ApiAuthError < StandardError; end
  
  # Raised when the HTTP request object passed is not supported
  class UnknownHTTPRequest < ApiAuthError; end
  
end
