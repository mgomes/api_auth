module ApiAuth
  module Middleware # :nodoc:
    class Excon # :nodoc:
      def initialize(stack)
        @stack = stack
      end

      def error_call(datum)
        @stack.error_call(datum)
      end

      def request_call(datum)
        request = ExconRequestWrapper.new(datum, @stack.query_string(datum))
        ApiAuth.sign!(request, datum[:api_auth_access_id], datum[:api_auth_secret_key])

        @stack.request_call(datum)
      end

      def response_call(datum)
        @stack.response_call(datum)
      end
    end

    class ExconRequestWrapper # :nodoc:
      attr_reader :datum, :query_string

      def initialize(datum, query_string)
        @datum = datum
        @query_string = query_string
      end

      def uri
        datum[:path] + query_string
      end

      def method
        datum[:method]
      end

      def headers
        datum[:headers]
      end

      def body
        datum[:body]
      end
    end
  end
end
