module ApiAuth
  module RequestDrivers # :nodoc:
    class HttpiRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        fetch_headers
        true
      end

      def set_auth_header(header)
        @request.headers['Authorization'] = header
        fetch_headers
        @request
      end

      def calculated_hash
        sha256_base64digest(@request.body || '')
      end

      def populate_content_hash
        return unless @request.body

        @request.headers['X-Authorization-Content-SHA256'] = calculated_hash
        fetch_headers
      end

      def content_hash_mismatch?
        if @request.body
          calculated_hash != content_hash
        else
          false
        end
      end

      def fetch_headers
        @headers = capitalize_keys @request.headers
      end

      def http_method
        nil # not possible to get the method at this layer
      end

      def content_type
        find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])
      end

      def content_hash
        find_header(%w[X-AUTHORIZATION-CONTENT-SHA256])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        @request.url.request_uri
      end

      def set_date
        @request.headers['DATE'] = Time.now.utc.httpdate
        fetch_headers
      end

      def timestamp
        find_header(%w[DATE HTTP_DATE])
      end

      def authorization_header
        find_header %w[Authorization AUTHORIZATION HTTP_AUTHORIZATION]
      end

      private

      def find_header(keys)
        keys.map { |key| @headers[key] }.compact.first
      end
    end
  end
end
