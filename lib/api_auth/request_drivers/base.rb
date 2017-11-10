module ApiAuth
  module RequestDrivers # :nodoc:
    class Base # :nodoc:
      include ApiAuth::Helpers

      def initialize(request, configuration = ApiAuth::Configuration.new)
        @request = request
        @configuration = configuration
        fetch_headers
        true
      end

      def authorization_header
        find_header %w(Authorization HTTP_AUTHORIZATION)
      end

      def fetch_headers
        raise NotImplementedError
      end

      def headers
        @headers
      end

      protected

      def find_header(keys)
        keys.map { |key| @headers[key] || @headers[key.upcase] || @headers[key.downcase] }.compact.first
      end
    end
  end
end
