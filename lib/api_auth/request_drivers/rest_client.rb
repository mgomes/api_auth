# give access to RestClient @processed_headers
module RestClient;class Request;attr_accessor :processed_headers;end;end

module ApiAuth

  module RequestDrivers # :nodoc:

    class RestClientRequest # :nodoc:

      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        true
      end

      def set_auth_header(header)
        @request.headers.merge!({ "Authorization" => header })
        save_headers # enforce update of processed_headers based on last updated headers
        @request
      end

      def calculated_md5
        p @request.payload.try(:read)
        Digest::MD5.base64digest(@request.payload.try(:read) || "")
      end

      def populate_content_md5
        if [:post, :put].include?(@request.method)
          @request.headers["CONTENT-MD5"] = calculated_md5
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
        capitalize_keys @request.headers
      end

      def content_type
        value = find_header(%w(CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE))
        value.nil? ? default_content_type_if_payload : value
      end
      
      def default_content_type_if_payload
        @request.payload ? 'application/x-www-form-urlencoded' : nil
      end

      def content_md5
        value = find_header(%w(CONTENT-MD5 CONTENT_MD5))
        value.nil? ? "" : value
      end

      def request_uri
        @request.url
      end

      def set_date
        @request.headers.merge!({ "DATE" => Time.now.utc.httpdate })
        save_headers
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
        keys.map { |key| fetch_headers[key] }.compact.first
      end
      
      def save_headers
        @request.processed_headers = @request.make_headers(fetch_headers)
      end      
    end

  end

end

require 'rest-client'
module ::RestClient
  class Request
    # attr_accessor :phantoms
    # 
    # alias :old_initialize :initialize 
    # def initialize args={}
    #   @is_phantom = args[:phantom]
    #   @phantoms = []
    #   5.times { |i| @phantoms << self.class.new(args.merge({:phantom => true})) unless args[:phantom] }
    #   @phantoms_read = 0
    #   old_initialize args
    # end
    # 
    
    alias :old_payload :payload
    def payload
      @payload_content ||= old_payload.try(:read)
      @payload_content ? OpenStruct.new(:read => @payload_content) : nil
    end
    
    # def safe_payload
    #   if !@is_phantom && @phantoms_read <= @phantoms.count - 1
    #     r = @phantoms[@phantoms_read].safe_payload
    #     @phantoms_read = @phantoms_read + 1
    #     r
    #   else
    #     r = payload
    #     puts r
    #     r
    #   end
    # end
  end
end