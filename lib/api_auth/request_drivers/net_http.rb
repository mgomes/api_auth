require 'time'
module ApiAuth
  module RequestDrivers # :nodoc:
    class NetHttpRequest < Base # :nodoc:
      def set_auth_header(header)
        @request['Authorization'] = header
        fetch_headers
        @request
      end

      def body
        if @request.respond_to?(:body_stream) && @request.body_stream
          body = @request.body_stream.read
          @request.body_stream.rewind
        else
          body = @request.body
        end
        body
      end

      def calculated_md5
        md5_base64digest(body || '')
      end

      def populate_content_md5
        return unless @request.class::REQUEST_HAS_BODY
        @request['Content-MD5'] = calculated_md5
        fetch_headers
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
        find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])
      end

      def content_md5
        find_header(%w[CONTENT-MD5 CONTENT_MD5])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        @request.path
      end

      def set_date
        @request[@configuration.date_header] = Time.now.utc.strftime(@configuration.date_format)
        fetch_headers
      end

      def timestamp
        find_header([@configuration.date_header, "HTTP_#{@configuration.date_header}"])
      end
    end
  end
end
