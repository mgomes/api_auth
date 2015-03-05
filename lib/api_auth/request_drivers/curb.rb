module ApiAuth

  module RequestDrivers # :nodoc:

    class CurbRequest < Base # :nodoc:

      def request_uri
        @request.url
      end

      protected

      def headers
        capitalize_keys @request.headers
      end

      def set_header field, value
        @request.headers.merge!({ "#{field}" => value })
      end

    end

  end

end
