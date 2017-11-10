module ApiAuth
  module CanonicalStringFactories
    class Standard # :nodoc:
      class << self
        def canonical_string(request, request_method)
          [request_method.upcase,
           request.content_type,
           request.content_md5,
           parse_uri(request.original_uri || request.request_uri),
           request.timestamp].join(',')
        end

        def parse_uri(uri)
          parsed_uri = URI.parse(uri)

          return parsed_uri.request_uri if parsed_uri.respond_to?(:request_uri)

          uri.empty? ? '/' : uri
        end
      end
    end
  end
end
