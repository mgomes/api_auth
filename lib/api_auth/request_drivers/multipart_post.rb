module ApiAuth

  module RequestDrivers # :nodoc:

    class MultipartPostRequest < NetHttpRequest # :nodoc:

      def calculated_md5
        body = @request.body_stream.read
        @request.body_stream.rewind

        md5_base64digest(body || '')
      end

    end

  end

end
