module ApiAuth
  module CanonicalStringFactories
    class Standard # :nodoc:
      class << self
        def canonical_string(request, request_method)
          [request_method.upcase,
           request.content_type,
           request.content_md5,
           parse_uri(request.request_uri),
           request.timestamp
          ].join(',')
        end

        URI_WITHOUT_HOST_REGEXP = %r{https?://[^,?/]*}

        def parse_uri(uri)
          uri_without_host = uri.gsub(URI_WITHOUT_HOST_REGEXP, '')
          return '/' if uri_without_host.empty?
          uri_without_host
        end
      end
    end
  end
end
