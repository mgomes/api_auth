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

      def calculated_hash
        body = @request.body.read
        @request.body.rewind
        sha256_base64digest(body)
      end

      def populate_content_hash
        return if !@request.put? && !@request.post?

        @request.env['HTTP_X_AUTHORIZATION_CONTENT_SHA256'] = calculated_hash
        save_headers
      end

      def content_hash_mismatch?
        if @request.put? || @request.post?
          calculated_hash != content_hash
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

      def content_hash
        find_header %w[HTTP_X_AUTHORIZATION_CONTENT_SHA256]
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
