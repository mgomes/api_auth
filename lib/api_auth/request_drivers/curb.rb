module ApiAuth
  module RequestDrivers # :nodoc:
    class CurbRequest < Base # :nodoc:

      def set_auth_header(header)
        @request.headers['Authorization'] = header
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
        find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])
      end

      def content_md5
        find_header(%w[CONTENT-MD5 CONTENT_MD5])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        @request.url
      end

      def set_date
        @request.headers[ApiAuth.configuration.date_header] = Time.now.utc.strftime(ApiAuth.configuration.date_format)
        fetch_headers
      end

      def timestamp
        value = find_header([ApiAuth.configuration.date_header, "HTTP_#{ApiAuth.configuration.date_header}"])
        value.nil? ? '' : value
      end

      protected

      def find_header(keys)
        keys.map { |key| @headers[key] || @headers[key.upcase] }.compact.first
      end
    end
  end
end
