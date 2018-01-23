module ApiAuth # :nodoc:
  class Configuration # :nodoc:
    attr_accessor :date_header, :date_format, :algorithm, :auth_header_factory,
                  :auth_header_pattern, :clock_skew

    def initialize
      @date_header = 'DATE'
      @date_format = '%a, %d %b %Y %T GMT'
      @algorithm = 'APIAuth'
      @auth_header_pattern = /#{@algorithm}(?:-HMAC-(MD5|SHA(?:1|224|256|384|512)?))? ([^:]+):(.+)$/
      @auth_header_factory = ApiAuth::AuthHeaderFactories::Standard
      # 900 seconds is 15 minutes
      @clock_skew = 900

      yield(self) if block_given?
    end
  end
end
