module ApiAuth
  module RequestDrivers # :nodoc:
    class ActionControllerRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request, authorize_md5: false)
        @request = request
        @authorize_md5 = authorize_md5
        fetch_headers
        true
      end

      def set_auth_header(header)
        @request.env['Authorization'] = header
        fetch_headers
        @request
      end

      def calculated_hash
        body = @request.raw_post
        hashes = [sha256_base64digest(body)]
        hashes << md5_base64digest(body) if @authorize_md5
        hashes
      end

      def populate_content_hash
        return unless @request.put? || @request.post?

        @request.env['X-AUTHORIZATION-CONTENT-SHA256'] = calculated_hash
        fetch_headers
      end

      def content_hash_mismatch?
        if @request.put? || @request.post?
          !calculated_hash.include?(content_hash)
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

      def content_hash
        headers = %w[X-AUTHORIZATION-CONTENT-SHA256 X_AUTHORIZATION_CONTENT_SHA256 HTTP_X_AUTHORIZATION_CONTENT_SHA256]
        headers += %w[CONTENT-MD5 CONTENT_MD5 HTTP_CONTENT_MD5] if @authorize_md5
        find_header(headers)
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        @request.request_uri
      end

      def set_date
        @request.env['HTTP_DATE'] = Time.now.utc.httpdate
        fetch_headers
      end

      def timestamp
        find_header(%w[DATE HTTP_DATE])
      end

      def authorization_header
        find_header %w[Authorization AUTHORIZATION HTTP_AUTHORIZATION]
      end

      private

      def find_header(keys)
        keys.map { |key| @headers[key] }.compact.first
      end
    end
  end
end
