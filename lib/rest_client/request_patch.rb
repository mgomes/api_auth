module RestClient
  # Adds accessor for processed_headers used by ApiAuth.
  class Request
    attr_accessor :processed_headers
  end
end
