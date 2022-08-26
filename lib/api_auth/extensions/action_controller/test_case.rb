require 'active_support/test_case'

module ActionController
  class TestCase < ActiveSupport::TestCase
    module Behavior

      def signed(request_method, action, access_id, secret_key, parameters = nil, session = nil, flash = nil)
        @request.env['API_AUTH_ACCESS_ID'] = access_id
        @request.env['API_AUTH_SECRET_KEY'] ||= secret_key
        __send__(request_method, action, parameters, session, flash).tap do
          @request.env.delete 'API_AUTH_ACCESS_ID'
          @request.env.delete 'API_AUTH_SECRET_KEY'
        end
      end

    end
  end

  class Base
    # Override so we can sign the request if the access_id and secret key have been set, now that all the headers have been set.
    def process(action, *args)
      ApiAuth.sign!(request, request.env['API_AUTH_ACCESS_ID'], request.env['API_AUTH_SECRET_KEY']) if request.env['API_AUTH_ACCESS_ID'] && request.env['API_AUTH_SECRET_KEY']
      super
    end
  end
end
