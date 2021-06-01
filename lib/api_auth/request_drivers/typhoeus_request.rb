module ApiAuth
  module RequestDrivers # :nodoc:
    class TyphoeusRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        fetch_headers
      end

      def set_auth_header(header)
        @request.options[:headers]['Authorization'] = header
        fetch_headers
        @request
      end

      def calculated_md5
        body = @request.options[:body] || ''
        md5_base64digest(body.to_s)
      end

      def populate_content_md5
        return unless %w[POST PUT].include?(http_method.to_s.upcase)

        @request.options[:headers]['Content-MD5'] = calculated_md5
        fetch_headers
      end

      def md5_mismatch?
        if %w[POST PUT].include?(http_method.to_s.upcase)
          calculated_md5 != content_md5
        else
          false
        end
      end

      def fetch_headers
        @headers = capitalize_keys(@request.options[:headers])
      end

      def http_method
        @request.options[:method].to_s.upcase
      end

      def content_type
        find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])
      end

      def content_md5
        find_header(%w[CONTENT-MD5 CONTENT_MD5 HTTP-CONTENT-MD5 HTTP_CONTENT_MD5])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        URI.parse(@request.url).request_uri
      end

      def set_date
        @request.options[:headers]['Date'] = Time.now.utc.httpdate
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
