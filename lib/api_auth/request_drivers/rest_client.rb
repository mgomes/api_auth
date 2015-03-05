# give access to RestClient @processed_headers
module RestClient;class Request;attr_accessor :processed_headers;end;end

module ApiAuth

  module RequestDrivers # :nodoc:

    class RestClientRequest < Base # :nodoc:

      def request_uri
        @request.url
      end

      protected

      def headers
        capitalize_keys @request.processed_headers
      end

      def body
        res = ''
        if @request.payload
          res = @request.payload.read
          @request.payload.instance_variable_get(:@stream).seek(0)
        end
        res
      end

      def set_header field, value
        @request.headers.merge!({ "#{field}" => value })
        @request.processed_headers = @request.make_headers(@request.headers)
      end

      def populatable_content_md5?
        [:post, :put].include?(@request.method)
      end

    end

  end

end
