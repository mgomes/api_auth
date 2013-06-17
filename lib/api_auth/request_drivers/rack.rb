module ApiAuth

  module RequestDrivers # :nodoc:

    class RackRequest # :nodoc:

      include ApiAuth::Helpers

      def initialize(request)
        @request = request
        @headers = fetch_headers
        true
      end

      def set_auth_header(header)
        @request.env.merge!({ "Authorization" => header })
        @headers = fetch_headers
        @request
      end

      def calculated_md5
        if @request.body
          _body = @request.body.read
        else
          _body = ''
        end
        p _body
        Digest::MD5.base64digest(_body)
      end

      def populate_content_md5
        if ['POST', 'PUT'].include?(@request.request_method)
          @request.env["Content-MD5"] = calculated_md5
        end
      end

      def md5_mismatch?
        if ['POST', 'PUT'].include?(@request.request_method)
          calculated_md5 != content_md5
        else
          false
        end
      end

      def fetch_headers
        capitalize_keys @request.env
      end

      def content_type
        value = find_header(%w(CONTENT-TYPE CONTENT_TYPE HTTP_CONTENT_TYPE))
        value.nil? ? "" : value
      end

      def content_md5
        value = find_header(%w(CONTENT-MD5 CONTENT_MD5 HTTP_CONTENT_MD5))
        value.nil? ? "" : value
      end

      def request_uri
        @request.url
      end

      def set_date
        @request.env.merge!({ "DATE" => Time.now.utc.httpdate })
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
        keys.map {|key| @headers[key] }.compact.first
      end
    end
  end
end

module Rack
  class Request
    # attr_accessor :phantoms
    # 
    # alias :old_initialize :initialize 
    # def initialize env, phantom=false
    #   @is_phantom = phantom
    #   @phantoms = []
    #   10.times { |i| @phantoms << self.class.new(env, true) unless phantom }
    #   @phantoms_read = 0
    #   old_initialize env
    # end

    # alias :old_body :body
    # def body
    #   @body_struct ||= old_body.read
    #   @bodystrg ||= (@body_struct ? /(?<=read=\").*(?=\")/.match(@body_struct)[0] : nil)
    #   @bodystrg ? OpenStruct.new(:read => @bodystrg) : nil
    # end
    
    alias :old_env :env
    def env
      @_rackInput ||= old_env['rack.input'].read
      @bodystrg ||= /(?<=read=\").*(?=\")/.match(@_rackInput).try(:[],0) || @_rackInput
      @_env ||= old_env.merge!({'rack.input' => (@bodystrg ? OpenStruct.new(:read => @bodystrg) : nil)})
      @_env
    end
    
    # def safe_body
    #   puts @is_phantom ? 'is phantom' : 'is not phantom'
    #   puts @phantoms_read
    #   puts "<="
    #   puts @phantoms.count - 1
    #   puts @phantoms_read <= @phantoms.count - 1
    #   if !@is_phantom && @phantoms_read <= @phantoms.count - 1
    #     r = @phantoms[@phantoms_read].safe_body
    #     @phantoms_read = @phantoms_read + 1
    #     r
    #   else
    #     r = body
    #     puts r
    #     r
    #   end
    # end
  end
end