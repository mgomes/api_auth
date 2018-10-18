module ApiAuth
  # Integration with Rails
  #
  class Rails # :nodoc:
    module ControllerMethods # :nodoc:
      module InstanceMethods # :nodoc:
        def get_api_access_id_from_request
          ApiAuth.access_id(request)
        end

        def api_authenticated?(secret_key)
          ApiAuth.authentic?(request, secret_key)
        end
      end

      ActionController::Base.send(:include, ControllerMethods::InstanceMethods) if defined?(ActionController::Base)
    end # ControllerMethods

    module ActiveResourceExtension # :nodoc:
      module ActiveResourceApiAuth # :nodoc:
        def self.included(base)
          base.extend(ClassMethods)
          base.class_attribute :hmac_access_id
          base.class_attribute :hmac_secret_key
          base.class_attribute :use_hmac
          base.class_attribute :api_auth_options
        end

        module ClassMethods
          def with_api_auth(access_id, secret_key, options = {})
            self.hmac_access_id = access_id
            self.hmac_secret_key = secret_key
            self.use_hmac = true
            self.api_auth_options = options

            class << self
              alias_method :connection_without_auth, :connection
              alias_method :connection,              :connection_with_auth
            end
          end

          def connection_with_auth(refresh = false)
            c = connection_without_auth(refresh)
            c.hmac_access_id = hmac_access_id
            c.hmac_secret_key = hmac_secret_key
            c.use_hmac = use_hmac
            c.api_auth_options = api_auth_options
            c
          end
        end # class methods

        module InstanceMethods
        end
      end # BaseApiAuth

      module Connection
        def self.included(base)
          base.send :alias_method, :request_without_auth, :request
          base.send :alias_method, :request,              :request_with_auth

          base.class_eval do
            attr_accessor :hmac_secret_key, :hmac_access_id, :use_hmac, :api_auth_options
          end
        end

        def request_with_auth(method, path, *arguments)
          if use_hmac && hmac_access_id && hmac_secret_key
            h = arguments.last
            tmp = "Net::HTTP::#{method.to_s.capitalize}".constantize.new(path, h)
            tmp.body = arguments[0] if arguments.length > 1
            ApiAuth.sign!(tmp, hmac_access_id, hmac_secret_key, api_auth_options)
            arguments.last['Content-MD5'] = tmp['Content-MD5'] if tmp['Content-MD5']
            arguments.last['DATE'] = tmp['DATE']
            arguments.last['Authorization'] = tmp['Authorization']
          end

          request_without_auth(method, path, *arguments)
        end
      end # Connection

      if defined?(ActiveResource)
        ActiveResource::Base.send(:include, ActiveResourceApiAuth)
        ActiveResource::Connection.send(:include, Connection)
      end
    end # ActiveResourceExtension
  end # Rails
end # ApiAuth
