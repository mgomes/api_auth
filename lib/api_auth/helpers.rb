module ApiAuth

  module Helpers # :nodoc:

    def b64_encode(string)
      if Base64.respond_to?(:strict_encode64)
        Base64.strict_encode64(string)
      else
        # Fall back to stripping out newlines on Ruby 1.8.
        Base64.encode64(string).gsub(/\n/, '')
      end
    end

    def md5_base64digest(string)
      if Digest::MD5.respond_to?(:base64digest)
        Digest::MD5.base64digest(string)
      else
        b64_encode(Digest::MD5.digest(string))
      end
    end

    # Capitalizes the keys of a hash
    def capitalize_keys(hsh)
      capitalized_hash = {}
      hsh.each_pair {|k,v| capitalized_hash[k.to_s.upcase] = v }
      capitalized_hash
    end

  end

end
