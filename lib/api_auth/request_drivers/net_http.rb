module ApiAuth
  module RequestDrivers # :nodoc:
    class NetHttpRequest < Base # :nodoc:

      def set_auth_header(header)
        @request['Authorization'] = header
        fetch_headers
        @request
      end

      def calculated_md5
        if @request.respond_to?(:body_stream) && @request.body_stream
          body = @request.body_stream.read
          @request.body_stream.rewind
        else
          body = @request.body
        end

        md5_base64digest(body || '')
      end

      def populate_content_md5
        if @request.class::REQUEST_HAS_BODY
          @request['Content-MD5'] = calculated_md5
          fetch_headers
        end
      end

      def md5_mismatch?
        if @request.class::REQUEST_HAS_BODY
          calculated_md5 != content_md5
        else
          false
        end
      end

      def fetch_headers
        @headers = {}
        @request.to_hash.map { |key, value| @headers[key] = value[0] }
      end

      def http_method
        @request.method.upcase
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
        @request.path
      end

      def set_date
        @request[ApiAuth.configuration.date_header] = Time.current.utc.strftime(ApiAuth.configuration.date_format)
        fetch_headers
      end

      def timestamp
        value = find_header([ApiAuth.configuration.date_header, "HTTP_#{ApiAuth.configuration.date_header}"])
        value.nil? ? '' : value
      end
    end
  end
end
