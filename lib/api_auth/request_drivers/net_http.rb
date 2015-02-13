module ApiAuth

  module RequestDrivers # :nodoc:

    class NetHttpRequest < Base # :nodoc:

      def request_uri
        @request.path
      end

      protected

      def headers
        @request
      end

      def body
        res = ''
        if @request.respond_to?(:body_stream) && @request.body_stream
          res = @request.body_stream.read
          @request.body_stream.rewind
        elsif @request.body
          res = @request.body
        end
        res
      end

      def set_header field, value
        @request["#{field}"] = value
      end

      def populatable_content_md5?
        @request.class::REQUEST_HAS_BODY
      end

    end

  end

end
