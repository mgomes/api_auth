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

  s.required_ruby_version = '>= 3.2.0'

  s.add_development_dependency 'actionpack', '>= 7.2'
  s.add_development_dependency 'activeresource', '>= 6.0'
  s.add_development_dependency 'activesupport', '>= 7.2'
  s.add_development_dependency 'amatch'
  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'curb', '~> 1.0'
  s.add_development_dependency 'excon', '~> 0.100'
  s.add_development_dependency 'faraday', '~> 2.0'
  s.add_development_dependency 'grape', '~> 2.0'
  s.add_development_dependency 'http', '~> 5.0'
  s.add_development_dependency 'httpi', '~> 4.0'
  s.add_development_dependency 'multipart-post', '~> 2.0'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rest-client', '~> 2.1'
  s.add_development_dependency 'rexml'
  s.add_development_dependency 'rspec', '~> 3.13'
  s.add_development_dependency 'rubocop', '~> 1.50'
  s.add_development_dependency 'typhoeus', '~> 1.4'

  s.files         = `git ls-files lib`.split($/) + ["LICENSE.txt", "CHANGELOG.md", "README.md", "VERSION"]
  s.require_paths = ['lib']
end
