require 'openssl'
require 'base64'

require 'api_auth/errors'
require 'api_auth/helpers'

require 'api_auth/request_drivers/net_http'
require 'api_auth/request_drivers/curb'
require 'api_auth/request_drivers/rest_client'
require 'api_auth/request_drivers/action_controller'
require 'api_auth/request_drivers/action_dispatch'
require 'api_auth/request_drivers/rack'
require 'api_auth/request_drivers/httpi'
require 'api_auth/request_drivers/faraday'

require 'api_auth/headers'
require 'api_auth/base'
require 'api_auth/railtie'

module ApiAuth # :nodoc:
  class << self
    attr_accessor :header_to_assign, :header_to_search
  end

  self.header_to_assign = 'Authorization'
  self.header_to_search = %w[Authorization AUTHORIZATION HTTP_AUTHORIZATION]
end
