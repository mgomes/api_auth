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

# The signed method for tests is modeled after the xhr method which was introduced in Rails 3 and will not work in earlier versions of Rails
require 'api_auth/extensions/action_controller/test_case' if defined?(Rails::VERSION::STRING) && Rails::VERSION::STRING >= '3' && Rails.env.test?
