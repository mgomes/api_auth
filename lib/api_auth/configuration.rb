module ApiAuth # :nodoc:
  class Configuration # :nodoc:
    attr_accessor :date_header, :date_format, :algorithm, :clock_skew

    def initialize
      @date_header = 'DATE'
      @date_format = '%a, %d %b %Y %T GMT'
      @algorithm = 'APIAuth'
      # 900 seconds is 15 minutes
      @clock_skew = 900

      yield(self) if block_given?
    end
  end
end
