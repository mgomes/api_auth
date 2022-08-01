require 'api_auth'

module Faraday
  module ApiAuth
    # Request middleware for Faraday. It takes the same arguments as ApiAuth.sign!.
    #
    # You will usually need to include it after the other middlewares since ApiAuth needs to hash
    # the final request.
    #
    # Usage:
    #
    # ```ruby
    # require 'faraday/api_auth'
    #
    # conn = Faraday.new do |f|
    #   f.request :api_auth, access_id, secret_key
    #   # Alternatively:
    #   # f.use Faraday::ApiAuth::Middleware, access_id, secret_key
    # end
    # ```
    #
    class Middleware < Faraday::Middleware
      def initialize(app, access_id, secret_key, options = {})
        super(app)
        @access_id = access_id
        @secret_key = secret_key
        @options = options
      end

      def on_request(env)
        ::ApiAuth.sign!(env, @access_id, @secret_key, @options)
      end
    end
  end
end
