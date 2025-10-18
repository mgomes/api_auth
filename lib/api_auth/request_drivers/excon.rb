module ApiAuth
  module RequestDrivers # :nodoc:
    class ExconRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
      end

      def set_auth_header(header)
        @request.headers['Authorization'] = header
        @request
      end

      def calculated_hash
        sha256_base64digest(body)
      end

      def populate_content_hash
        return unless %w[POST PUT].include?(http_method)

        @request.headers['X-Authorization-Content-SHA256'] = calculated_hash
      end

      def content_hash_mismatch?
        if %w[POST PUT].include?(http_method)
          calculated_hash != content_hash
        else
          false
        end
      end

      def http_method
        @request.method.to_s.upcase
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
        @request.uri
      end

      def set_date
        @request.headers['DATE'] = Time.now.utc.httpdate
      end

      def timestamp
        find_header(%w[DATE HTTP_DATE])
      end

      def authorization_header
        find_header %w[Authorization AUTHORIZATION HTTP_AUTHORIZATION]
      end

      def fetch_headers
        capitalize_keys(@request.headers)
      end

      private

      def body
        source = @request.body

        return '' if source.nil?

        if source.respond_to?(:read)
          contents = source.read
          source.rewind if source.respond_to?(:rewind)
          contents
        else
          source.to_s
        end
      end

      def find_header(keys)
        headers = capitalize_keys(@request.headers)
        keys.map { |key| headers[key] }.compact.first
      end
    end
  end
end
