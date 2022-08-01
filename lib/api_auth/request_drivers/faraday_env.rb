module ApiAuth
  module RequestDrivers # :nodoc:
    # Internally, Faraday uses the class Faraday::Env to represent requests. The class is not meant
    # to be directly exposed to users, but this is what Faraday middlewares work with. See
    # <https://lostisland.github.io/faraday/middleware/>.
    class FaradayEnv
      include ApiAuth::Helpers

      def initialize(env)
        @env = env
      end

      def set_auth_header(header)
        @env.request_headers['Authorization'] = header
        @env
      end

      def calculated_hash
        sha256_base64digest(body)
      end

      def populate_content_hash
        return unless %w[POST PUT PATCH].include?(http_method)

        @env.request_headers['X-Authorization-Content-SHA256'] = calculated_hash
      end

      def content_hash_mismatch?
        if %w[POST PUT PATCH].include?(http_method)
          calculated_hash != content_hash
        else
          false
        end
      end

      def http_method
        @env.method.to_s.upcase
      end

      def content_type
        type = find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])

        # When sending a body-less POST request, the Content-Type is set at the last minute by the
        # Net::HTTP adapter, which states in the documentation for Net::HTTP#post:
        #
        # > You should set Content-Type: header field for POST. If no Content-Type: field given,
        # > this method uses “application/x-www-form-urlencoded” by default.
        #
        # The same applies to PATCH and PUT. Hopefully the other HTTP adapters behave similarly.
        #
        type ||= 'application/x-www-form-urlencoded' if %w[POST PATCH PUT].include?(http_method)

        type
      end

      def content_hash
        find_header(%w[X-AUTHORIZATION-CONTENT-SHA256])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        @env.url.request_uri
      end

      def set_date
        @env.request_headers['Date'] = Time.now.utc.httpdate
      end

      def timestamp
        find_header(%w[DATE HTTP_DATE])
      end

      def authorization_header
        find_header(%w[Authorization AUTHORIZATION HTTP_AUTHORIZATION])
      end

      def body
        body_source = @env.request_body
        if body_source.respond_to?(:read)
          result = body_source.read
          body_source.rewind
          result
        else
          body_source.to_s
        end
      end

      def fetch_headers
        capitalize_keys @env.request_headers
      end

      private

      def find_header(keys)
        keys.map { |key| @env.request_headers[key] }.compact.first
      end
    end
  end
end
