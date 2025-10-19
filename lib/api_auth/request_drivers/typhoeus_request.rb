module ApiAuth
  module RequestDrivers # :nodoc:
    class TyphoeusRequest # :nodoc:
      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        @headers = fetch_headers
      end

      def set_auth_header(header)
        headers_hash['Authorization'] = header
        @headers = fetch_headers
        @request
      end

      def calculated_hash
        sha256_base64digest(body)
      end

      def populate_content_hash
        return unless %w[POST PUT].include?(http_method)

        headers_hash['X-Authorization-Content-SHA256'] = calculated_hash
        @headers = fetch_headers
      end

      def content_hash_mismatch?
        if %w[POST PUT].include?(http_method)
          calculated_hash != content_hash
        else
          false
        end
      end

      def fetch_headers
        @headers = capitalize_keys(headers_hash)
      end

      def http_method
        method = @request.options[:method]
        method&.to_s&.upcase
      end

      def content_type
        find_header(%w[CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE])
      end

      def content_hash
        find_header(%w[X-AUTHORIZATION-CONTENT-SHA256])
      end

      def original_uri
        find_header(%w[X-ORIGINAL-URI X_ORIGINAL_URI HTTP_X_ORIGINAL_URI])
      end

      def request_uri
        canonical_request_uri(@request.base_url, params_query, include_query: true)
      end

      def set_date
        headers_hash['DATE'] = Time.now.utc.httpdate
        @headers = fetch_headers
      end

      def timestamp
        find_header(%w[DATE HTTP_DATE])
      end

      def authorization_header
        find_header %w[Authorization AUTHORIZATION HTTP_AUTHORIZATION]
      end

      private

      def body
        encoded = @request.respond_to?(:encoded_body) ? @request.encoded_body : nil
        return '' if encoded.nil?
        return encoded unless encoded.empty?

        source = @request.options[:body]
        return '' if source.nil?

        if source.respond_to?(:read)
          contents = source.read
          source.rewind if source.respond_to?(:rewind)
          contents
        else
          source.to_s
        end
      end

      def params_query
        params = @request.options[:params]
        return nil if params.nil?
        return params if params.is_a?(String)
        return nil if params.respond_to?(:empty?) && params.empty?

        Typhoeus::Pool.with_easy do |easy|
          query = Ethon::Easy::Params.new(easy, params)
          if @request.options.key?(:params_encoding) && query.respond_to?(:params_encoding=)
            query.params_encoding = @request.options[:params_encoding]
          end
          query.escape = true
          query.to_s
        end
      end

      def headers_hash
        @request.options[:headers] ||= {}
      end

      def find_header(keys)
        keys.map { |key| @headers[key] }.compact.first
      end
    end
  end
end
