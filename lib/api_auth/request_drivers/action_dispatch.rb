module ApiAuth
  module RequestDrivers # :nodoc:
    class ActionDispatchRequest < ActionControllerRequest # :nodoc:
      def request_uri
        @request.original_fullpath
      end
    end
  end
end
