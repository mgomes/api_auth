require_relative 'api_auth/middleware'

module Faraday
  # Integrate ApiAuth into Faraday.
  module ApiAuth
    Faraday::Request.register_middleware(api_auth: Middleware)
  end
end
