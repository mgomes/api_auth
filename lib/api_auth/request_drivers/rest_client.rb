# give access to RestClient @processed_headers
module RestClient; class Request; attr_accessor :processed_headers; end; end

module ApiAuth
  module RequestDrivers # :nodoc:
    class RestClientRequest < Base # :nodoc:

      def set_auth_header(header)
        @request.headers['Authorization'] = header
        save_headers # enforce update of processed_headers based on last updated headers
        @request
      end

      def calculated_md5
        if @request.payload
          body = @request.payload.read
          @request.payload.instance_variable_get(:@stream).seek(0)
        else
          body = ''
        end
        md5_base64digest(body)
      end

      def populate_content_md5
        if [:post, :put].include?(@request.method)
          @request.headers['Content-MD5'] = calculated_md5
          save_headers
        end
      end

      def md5_mismatch?
        if [:post, :put].include?(@request.method)
          calculated_md5 != content_md5
        else
          false
        end
      end

      def fetch_headers
        @headers = capitalize_keys @request.processed_headers
      end

      def http_method
        @request.method.to_s.upcase
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
        @request.url
      end

      def set_date
        @request.headers[ApiAuth.configuration.date_header] = Time.now.utc.strftime(ApiAuth.configuration.date_format)
        save_headers
      end

      def timestamp
        value = find_header([ApiAuth.configuration.date_header, "HTTP_#{ApiAuth.configuration.date_header}"])
        value.nil? ? '' : value
      end

      private

      def save_headers
        @request.processed_headers = @request.make_headers(@request.headers)
        fetch_headers
      end
    end
  end
end
