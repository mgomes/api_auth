module ApiAuth
  module Helpers # :nodoc:
    def b64_encode(string)
      Base64.strict_encode64(string)
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
  end
end
