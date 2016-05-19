module ApiAuth
  module RequestDrivers # :nodoc:
    class RackRequest < Base # :nodoc:

      def set_auth_header(header)
        @request.env['Authorization'] = header
        fetch_headers
        @request
      end

      def calculated_md5
        if @request.body
          body = @request.body.read
          @request.body.rewind
        else
          body = ''
        end
        md5_base64digest(body)
      end

      def populate_content_md5
        if %w(POST PUT).include?(@request.request_method)
          @request.env['Content-MD5'] = calculated_md5
          fetch_headers
        end
      end

      def md5_mismatch?
        if %w(POST PUT).include?(@request.request_method)
          calculated_md5 != content_md5
        else
          false
        end
      end

      def fetch_headers
        @headers = capitalize_keys @request.env
      end

      def http_method
        @request.request_method.upcase
      end

      def content_type
        value = find_header(%w(CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE))
        value.nil? ? '' : value
      end

      def content_md5
        value = find_header(%w(CONTENT-MD5 CONTENT_MD5 HTTP-CONTENT-MD5 HTTP_CONTENT_MD5))
        value.nil? ? '' : value
      end

      def request_uri
        @request.fullpath
      end

      def set_date
        @request.env[ApiAuth.configuration.date_header] = Time.now.utc.strftime(ApiAuth.configuration.date_format)
        fetch_headers
      end

      def timestamp
        value = find_header([ApiAuth.configuration.date_header, "HTTP_#{ApiAuth.configuration.date_header}"])
        value.nil? ? '' : value
      end
    end
  end
end
