module ApiAuth
  module RequestDrivers # :nodoc:
    class Base # :nodoc:
      include ApiAuth::Helpers

      attr_reader :headers

      def initialize(request, configuration = ApiAuth::Configuration.new)
        @request = request
        @configuration = configuration
        fetch_headers
      end

      def authorization_header
        find_header %w[Authorization HTTP_AUTHORIZATION]
      end

      def fetch_headers
        raise NotImplementedError
      end

      protected

      def find_header(keys)
        keys.map { |key| @headers[key] || @headers[key.upcase] || @headers[key.downcase] }.compact.first
      end
    end
  end
end
