module ApiAuth # :nodoc:
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  class Configuration # :nodoc:
    attr_accessor :date_header, :date_format, :algorithm, :auth_header_factory,
                  :canonical_string_factory, :signer, :auth_header_pattern

    def initialize
      @date_header = 'DATE'
      @date_format = '%a, %d %b %Y %T GMT'
      @algorithm = 'APIAuth'
      @auth_header_pattern = /#{@algorithm}(?:-HMAC-(MD[245]|SHA(?:1|224|256|384|512)*))? ([^:]+):(.+)$/
      @auth_header_factory = ApiAuth::AuthHeaderFactories::Standard
      @canonical_string_factory = ApiAuth::CanonicalStringFactories::Standard
      @signer = ApiAuth::Signers::Standard
    end
  end
end
ApiAuth.configure
