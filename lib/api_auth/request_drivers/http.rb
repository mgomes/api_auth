module ApiAuth
  module RequestDrivers # :nodoc:
    class HttpRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
      end

      def set_auth_header(header)
        @request['Authorization'] = header
        @request
      end

      def calculated_md5
        body = ''
        @request.body.each { |chunk| body << chunk }
        @request.body.source.rewind if @request.body.source.respond_to?(:rewind)
        md5_base64digest(body)
      end

      def populate_content_md5
        return unless %w[POST PUT].include?(http_method)
        @request['Content-MD5'] = calculated_md5
      end

      def md5_mismatch?
        if %w[POST PUT].include?(http_method)
          calculated_md5 != content_md5
        else
          false
        end
      end

      def http_method
        @request.verb.to_s.upcase
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
        @request.uri.request_uri
      end

      def set_date
        @request['Date'] = Time.now.utc.httpdate
      end

      def timestamp
        find_header(%w[DATE HTTP_DATE])
      end

      def authorization_header
        find_header %w[Authorization AUTHORIZATION HTTP_AUTHORIZATION]
      end

      private

      def find_header(keys)
        keys.map { |key| @request[key] }.compact.first
      end
    end
  end
end
