module ApiAuth
  module RequestDrivers # :nodoc:
    class ActionDispatchRequest < ActionControllerRequest # :nodoc:
      def request_uri
        if @request.respond_to?(:original_fullpath)
          @request.original_fullpath
        else
          @request.fullpath
        end
      end
    end
  end
end
