require 'uri'

module ApiAuth
  module Helpers # :nodoc:
    def b64_encode(string)
      Base64.strict_encode64(string)
    end

    def sha256_base64digest(string)
      Digest::SHA256.base64digest(string)
    end

    def md5_base64digest(string)
      Digest::MD5.base64digest(string)
    end

    # Capitalizes the keys of a hash
    def capitalize_keys(hsh)
      capitalized_hash = {}
      hsh.each_pair { |k, v| capitalized_hash[k.to_s.upcase] = v }
      capitalized_hash
    end

    def value_blank?(value)
      case value
      when nil, false
        true
      when String, Array, Hash
        value.empty?
      else
        value.respond_to?(:empty?) ? value.empty? : false
      end
    end

    def value_present?(value)
      !value_blank?(value)
    end

    def canonical_request_uri(base_url, additional_query = nil)
      base = base_url.to_s
      return '/' if base.empty?

      uri = URI.parse(base)
      merged_query = merge_query_strings(uri.query, normalize_query_component(additional_query))
      uri.query = merged_query if value_present?(merged_query)

      result = uri.respond_to?(:request_uri) ? uri.request_uri : uri.to_s
      value_present?(result) ? result : '/'
    rescue URI::InvalidURIError
      '/'
    end

    private

    def merge_query_strings(*queries)
      combined = queries.compact.map(&:to_s).reject(&:empty?).join('&')
      combined.empty? ? nil : combined
    end

    def normalize_query_component(component)
      case component
      when nil
        nil
      when String
        component.empty? ? nil : component
      when Hash
        component.empty? ? nil : URI.encode_www_form(component)
      else
        component.to_s
      end
    end
  end
end
