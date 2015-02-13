module ApiAuth

  module RequestDrivers # :nodoc:

    class RackRequest < Base # :nodoc:

      def request_uri
        @request.url
      end

      protected

      def headers
        capitalize_keys @request.env
      end

      def body
        res = ''
        if @request.body
          res = @request.body.read
          @request.body.rewind
        end
        res
      end

      def set_header field, value
        @request.env.merge!({ "#{field}" => value })
      end

      def populatable_content_md5?
        ['POST', 'PUT'].include?(@request.request_method)
      end

    end

  end

end
