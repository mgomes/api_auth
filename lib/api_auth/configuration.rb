module ApiAuth # :nodoc:
  class Configuration # :nodoc:
    attr_accessor :date_header, :date_format, :algorithm,  :canonical_string_factory,
                  :clock_skew

    def initialize
      @date_header = 'DATE'
      @date_format = '%a, %d %b %Y %T GMT'
      @algorithm = 'APIAuth'
      @canonical_string_factory = ApiAuth::CanonicalStringFactories::Standard
      # 900 seconds is 15 minutes
      @clock_skew = 900

      yield(self) if block_given?
    end
  end
end
