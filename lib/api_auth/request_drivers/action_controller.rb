module ApiAuth

  module RequestDrivers # :nodoc:

    class ActionControllerRequest < Base # :nodoc:

      def request_uri
        @request.request_uri
      end

      def set_date(date_header = 'HTTP_DATE')
        super date_header
      end

      protected

      def headers
        capitalize_keys @request.env
      end

      def body
        @request.raw_post
      end

      def set_header field, value
        @request.env["#{field}"] = value
      end

      def populatable_content_md5?
        @request.put? || @request.post?
      end

    end

  end

end
