# give access to RestClient @processed_headers
module RestClient;class Request;attr_accessor :processed_headers;end;end

module ApiAuth

  module RequestDrivers # :nodoc:

    class RestClientRequest # :nodoc:

      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        @headers = fetch_headers
        true
      end

      def set_auth_header(header)
        update_headers!({ "Authorization" => header })
        @request
      end
      
      def calculated_md5
        if @request.payload
          body = @request.payload.read
          @request.payload.instance_variable_get(:@stream).seek(0)
        else
          body = ''
        end
        Digest::MD5.base64digest(body)
      end

      def populate_content_md5
        if [:post, :put].include?(@request.method)
          update_headers!({ "Content-MD5" => calculated_md5 })
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
        capitalize_keys @request.headers
      end

      def content_type
        value = find_header(%w(CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE))
        value.nil? ? default_content_type : value
      end

      def content_md5
        value = find_header(%w(CONTENT-MD5 CONTENT_MD5))
        value.nil? ? "" : value
      end

      def request_uri
        @request.url
      end

      def set_date
        update_headers!({ "DATE" => Time.now.utc.httpdate })
      end

      def timestamp
        value = find_header(%w(DATE HTTP_DATE))
        value.nil? ? "" : value
      end

      def authorization_header
        find_header %w(Authorization AUTHORIZATION HTTP_AUTHORIZATION)
      end

    private

      def find_header(keys)
        keys.map {|key| fetch_headers[key] }.compact.first
      end

      def update_headers! new_headers_hash
        @request.headers.merge!(new_headers_hash)
        @headers = fetch_headers
        # enforce update of processed_headers based on last updated headers
        @request.processed_headers = @request.make_headers(@headers)   
      end
      
      def default_content_type
        @request.payload ? 'application/x-www-form-urlencoded' : nil
      end
    end

  end

end
