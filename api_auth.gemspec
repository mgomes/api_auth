$LOAD_PATH.push File.expand_path('lib', __dir__)

Gem::Specification.new do |s|
  s.name = 'api-auth'
  s.summary = 'Simple HMAC authentication for your APIs'
  s.description = 'Full HMAC auth implementation for use in your gems and Rails apps.'
  s.homepage = 'https://github.com/mgomes/api_auth'
  s.version = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.authors = ['Mauricio Gomes']
  s.email = 'mauricio@edge14.com'
  s.license = 'MIT'

  s.metadata = {
    'rubygems_mfa_required' => 'true'
  }

  s.required_ruby_version = '>= 2.6.0'

  s.add_development_dependency 'actionpack', '>= 6.0'
  s.add_development_dependency 'activeresource', '>= 4.0'
  s.add_development_dependency 'activesupport', '>= 6.0'
  s.add_development_dependency 'amatch'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'curb', '~> 1.0'
  # DRb is required for Ruby 3.4+ but must avoid 2.0.6 which breaks Ruby 2.6
  s.add_development_dependency 'drb', '>= 2.0.4', '< 2.0.6'
  s.add_development_dependency 'faraday', '>= 1.1.0'
  s.add_development_dependency 'grape', '~> 2.0'
  s.add_development_dependency 'http'
  s.add_development_dependency 'httpi'
  s.add_development_dependency 'multipart-post', '~> 2.0'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rest-client', '~> 2.0'
  s.add_development_dependency 'rexml'
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'rubocop', '~> 1.50'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
