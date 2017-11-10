module ApiAuth
  module AuthHeaderFactories
    class Standard # :nodoc:
      def self.auth_header(_headers, access_id, options, signature)
        hmac_string = "-HMAC-#{options[:digest].upcase}" unless options[:digest] == 'sha1'
        "#{options[:configuration].algorithm}#{hmac_string} #{access_id}:#{signature}"
      end
    end
  end
end
