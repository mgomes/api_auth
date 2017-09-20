module ApiAuth
  module RequestDrivers # :nodoc:
    class ExconRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
      end

      def set_auth_header(header)
        @request.headers['Authorization'] = header
        @request
      end

      def calculated_md5
        md5_base64digest(@request.body || '')
      end

      def populate_content_md5
        return unless @request.body
        @request.headers['Content-MD5'] = calculated_md5
      end

      def md5_mismatch?
        if @request.body
          calculated_md5 != content_md5
        else
          false
        end
      end

      def http_method
        @request.method
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
        @request.uri
      end

      def set_date
        @request.headers['DATE'] = Time.now.utc.httpdate
      end

      def timestamp
        find_header(%w[DATE HTTP_DATE])
      end

      def authorization_header
        find_header %w[Authorization AUTHORIZATION HTTP_AUTHORIZATION]
      end

      private

      def find_header(keys)
        headers = capitalize_keys(@request.headers)
        keys.map { |key| headers[key] }.compact.first
      end
    end
  end
end
