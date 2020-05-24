module ApiAuth
  module RequestDrivers # :nodoc:
    class NetHttpRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        @headers = fetch_headers
        true
      end

      def set_auth_header(header)
        @request['Authorization'] = header
        @headers = fetch_headers
        @request
      end

      def calculated_hash
        if @request.respond_to?(:body_stream) && @request.body_stream
          body = @request.body_stream.read
          @request.body_stream.rewind
        else
          body = @request.body
        end

        sha256_base64digest(body || '')
      end

      def populate_content_hash
        return unless @request.class::REQUEST_HAS_BODY

        @request['X-Authorization-Content-SHA256'] = calculated_hash
      end

      def content_hash_mismatch?
        if @request.class::REQUEST_HAS_BODY
          calculated_hash != content_hash
        else
          false
        end
      end

      def fetch_headers
        @request
      end

      def http_method
        @request.method.upcase
      end

      def content_type
        find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])
      end

      def content_hash
        find_header(%w[X-Authorization-Content-SHA256])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        @request.path
      end

      def set_date
        @request['DATE'] = Time.now.utc.httpdate
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
