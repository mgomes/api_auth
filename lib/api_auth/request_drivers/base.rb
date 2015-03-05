module ApiAuth

  module RequestDrivers # :nodoc:

    class Base # :nodoc:

      include ApiAuth::Helpers

      DATE_HEADERS = %w(X_HMAC_DATE HTTP_X_HMAC_DATE DATE HTTP_DATE)
      CONTENT_MD5_HEADERS = %w(X_HMAC_CONTENT_MD5 HTTP_X_HMAC_CONTENT_MD5 CONTENT_MD5 HTTP_CONTENT_MD5 HTTP-CONTENT-MD5 CONTENT-MD5)
      CONTENT_TYPE_HEADERS = %w(X_HMAC_CONTENT_TYPE HTTP_X_HMAC_CONTENT_TYPE CONTENT_TYPE HTTP_CONTENT_TYPE CONTENT-TYPE HTTP-CONTENT-TYPE)
      AUTHORIZATION_HEADERS = %w(X_HMAC_AUTHORIZATION HTTP_X_HMAC_AUTHORIZATION AUTHORIZATION HTTP_AUTHORIZATION)

      def self.initialize_appropiate_driver(request)
        case request.class.to_s
        when /Net::HTTP/
          NetHttpRequest.new(request)
        when /RestClient/
          RestClientRequest.new(request)
        when /Curl::Easy/
          CurbRequest.new(request)
        when /ActionController::Request/, /ActionController::CgiRequest/
          ActionControllerRequest.new(request)
        when /ActionController::TestRequest/
          defined?(ActionDispatch) ? ActionDispatchRequest.new(request) : ActionControllerRequest.new(request)
        when /ActionDispatch::Request/
          ActionDispatchRequest.new(request)
        when /HTTPI::Request/
          HttpiRequest.new(request)
        when /Rack::Request/
          RackRequest.new(request)
        else
          raise UnknownHTTPRequest, "#{request.class.to_s} is not yet supported."
        end
      end

      def initialize(request)
        @request = request
        true
      end

      # Sets the request's authorization header with the passed in value.
      # The header should be the ApiAuth HMAC signature.
      #
      # This will return the original request object with the signed Authorization
      # header already in place.
      def set_auth_header(header)
        set_header 'Authorization', header
        @request
      end

      def set_content_md5
        return if content_md5.present?
        set_header('Content-MD5', calculated_md5) if populatable_content_md5?
      end

      def calculated_md5
        md5_base64digest(body)
      end

      def md5_match?
        return true if content_md5.empty?
        populatable_content_md5? ? calculated_md5 == content_md5 : true
      end

      def content_type
        find_header CONTENT_TYPE_HEADERS
      end

      def content_md5
        find_header CONTENT_MD5_HEADERS
      end

      def timestamp
        find_header DATE_HEADERS
      end

      def set_date(date_header = 'DATE')
        set_header date_header, Time.now.utc.httpdate if timestamp.empty?
      end

      def authorization_header
        find_header AUTHORIZATION_HEADERS
      end

      protected

      def find_header(keys)
        x_headers = headers
        keys.map { |key| x_headers[key] }.compact.first || ''
      end

      def populatable_content_md5?
        false
      end

    end

  end

end
