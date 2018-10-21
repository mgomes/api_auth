module ApiAuth
  module RequestDrivers # :nodoc:
    class GrapeRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        save_headers
        true
      end

      def set_auth_header(header)
        @request.env['HTTP_AUTHORIZATION'] = header
        save_headers # enforce update of processed_headers based on last updated headers
        @request
      end

      def calculated_md5
        body = @request.body.read
        @request.body.rewind
        md5_base64digest(body)
      end

      def populate_content_md5
        return if !@request.put? && !@request.post?

        @request.env['HTTP_CONTENT_MD5'] = calculated_md5
        save_headers
      end

      def md5_mismatch?
        if @request.put? || @request.post?
          calculated_md5 != content_md5
        else
          false
        end
      end

      def fetch_headers
        capitalize_keys @request.env
      end

      def http_method
        @request.request_method.upcase
      end

      def content_type
        find_header %w[HTTP_X_HMAC_CONTENT_TYPE HTTP_X_CONTENT_TYPE CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE]
      end

      def content_md5
        find_header %w[HTTP_X_HMAC_CONTENT_MD5 HTTP_X_CONTENT_MD5 CONTENT-MD5 CONTENT_MD5 HTTP_CONTENT_MD5]
      end

      def original_uri
        find_header %w[HTTP_X_HMAC_ORIGINAL_URI HTTP_X_ORIGINAL_URI X-ORIGINAL-URI X_ORIGINAL_URI]
      end

      def request_uri
        @request.url
      end

      def set_date
        @request.env['HTTP_DATE'] = Time.now.utc.httpdate
        save_headers
      end

      def timestamp
        find_header %w[HTTP_X_HMAC_DATE HTTP_X_DATE DATE HTTP_DATE]
      end

      def authorization_header
        find_header %w[HTTP_X_HMAC_AUTHORIZATION HTTP_X_AUTHORIZATION Authorization AUTHORIZATION HTTP_AUTHORIZATION]
      end

      private

      def find_header(keys)
        keys.map { |key| @headers[key] }.compact.first
      end

      def save_headers
        @headers = fetch_headers
      end
    end
  end
end
