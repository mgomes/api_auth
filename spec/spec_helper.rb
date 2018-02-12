$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'

require 'active_support'
require 'active_support/test_case'
require 'action_controller'
require 'action_controller/test_case'
require 'active_resource'
require 'active_resource/http_mock'

require 'api_auth'
require 'amatch'
require 'rest_client'
require 'curb'
require 'http'
require 'httpi'
require 'faraday'
require 'net/http/post/multipart'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
