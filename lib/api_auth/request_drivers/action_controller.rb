module ApiAuth
  module RequestDrivers # :nodoc:
    class ActionControllerRequest < Base # :nodoc:
      def set_auth_header(header)
        @request.env['Authorization'] = header
        fetch_headers
        @request
      end

      def body
        @request.raw_post
      end

      def calculated_md5
        md5_base64digest(body)
      end

      def populate_content_md5
        return unless @request.put? || @request.post?
        @request.env['Content-MD5'] = calculated_md5
        fetch_headers
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
        find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])
      end

      def content_md5
        find_header(%w[CONTENT-MD5 CONTENT_MD5 HTTP_CONTENT_MD5])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        @request.request_uri
      end

      def set_date
        @request.env["HTTP_#{@configuration.date_header}"] = Time.now.utc.strftime(@configuration.date_format)
        fetch_headers
      end

      def timestamp
        find_header([@configuration.date_header, "HTTP_#{@configuration.date_header}"])
      end
    end
  end
end
