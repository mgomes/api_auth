module ApiAuth

  module RequestDrivers # :nodoc:

    class HttpiRequest < Base # :nodoc:

      def request_uri
        @request.url.request_uri
      end

      protected

      def headers
        capitalize_keys @request.headers
      end

      def body
        @request.body || ''
      end

      def set_header field, value
        @request.headers["#{field}"] = value
      end

      def populatable_content_md5?
        @request.body.present?
      end

    end

  end

end
