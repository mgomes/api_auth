module ApiAuth
  module RequestDrivers # :nodoc:
    class ActionControllerRequest < Base # :nodoc:

      def set_auth_header(header)
        @request.env['Authorization'] = header
        fetch_headers
        @request
      end

      def calculated_md5
        body = @request.raw_post
        md5_base64digest(body)
      end

      def populate_content_md5
        if @request.put? || @request.post?
          @request.env['Content-MD5'] = calculated_md5
          fetch_headers
        end
      end

      def md5_mismatch?
        if (@request.put? || @request.post?) && !@request.body.nil?
          calculated_md5 != content_md5
        else
          false
        end
      end

      def fetch_headers
        @headers = capitalize_keys @request.env
      end

      def http_method
        @request.request_method.to_s.upcase
      end

      def content_type
        value = find_header(%w(CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE))
        value.nil? ? '' : value
      end

      def content_md5
        value = find_header(%w(CONTENT-MD5 CONTENT_MD5 HTTP_CONTENT_MD5))
        value.nil? ? '' : value
      end

      def request_uri
        @request.request_uri
      end

      def set_date
        @request.env["HTTP_#{ApiAuth.configuration.date_header}"] = Time.current.utc.strftime(ApiAuth.configuration.date_format)
        fetch_headers
      end

      def timestamp
        value = find_header([ApiAuth.configuration.date_header, "HTTP_#{ApiAuth.configuration.date_header}"])
        value.nil? ? '' : value
      end
    end
  end
end
