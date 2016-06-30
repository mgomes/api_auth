module ApiAuth
  module RequestDrivers # :nodoc:
    class HttpiRequest < Base # :nodoc:

      def set_auth_header(header)
        @request.headers['Authorization'] = header
        fetch_headers
        @request
      end

      def calculated_md5
        md5_base64digest(@request.body || '')
      end

      def populate_content_md5
        if @request.body
          @request.headers['Content-MD5'] = calculated_md5
          fetch_headers
        end
      end

      def md5_mismatch?
        if @request.body
          calculated_md5 != content_md5
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
        value = find_header(%w(CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE))
        value.nil? ? '' : value
      end

      def content_md5
        value = find_header(%w(CONTENT-MD5 CONTENT_MD5))
        value.nil? ? '' : value
      end

      def request_uri
        @request.url.request_uri
      end

      def set_date
        @request.headers[ApiAuth.configuration.date_header] = Time.now.utc.strftime(ApiAuth.configuration.date_format)
        fetch_headers
      end

      def timestamp
        value = find_header([ApiAuth.configuration.date_header, "HTTP_#{ApiAuth.configuration.date_header}"])
        value.nil? ? '' : value
      end
    end
  end
end
