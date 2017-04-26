module ApiAuth
  module RequestDrivers # :nodoc:
    class CurbRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        fetch_headers
        true
      end

      def set_auth_header(header)
        @request.headers[ApiAuth.header_to_assign] = header
        fetch_headers
        @request
      end

      def populate_content_md5
        nil # doesn't appear to be possible
      end

      def md5_mismatch?
        false
      end

      def fetch_headers
        @headers = capitalize_keys @request.headers
      end

      def http_method
        nil # not possible to get the method at this layer
      end

      def content_type
        value = find_header(%w(CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE))
        value.nil? ? '' : value
      end

      def content_md5
        value = find_header(%w(CONTENT-MD5 CONTENT_MD5))
        value.nil? ? '' : value
      end

      def original_uri
        find_header(%w(X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI))
      end

      def request_uri
        @request.url
      end

      def set_date
        @request.headers['DATE'] = Time.now.utc.httpdate
        fetch_headers
      end

      def timestamp
        value = find_header(%w(DATE HTTP_DATE))
        value.nil? ? '' : value
      end

      def authorization_header
        find_header ApiAuth.header_to_search
      end

      private

      def find_header(keys)
        keys.map { |key| @headers[key] }.compact.first
      end
    end
  end
end
