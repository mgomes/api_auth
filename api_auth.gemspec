$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name = 'api-auth'
  s.summary = 'Simple HMAC authentication for your APIs'
  s.description = 'Full HMAC auth implementation for use in your gems and Rails apps.'
  s.homepage = 'https://github.com/mgomes/api_auth'
  s.version = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.authors = ['Mauricio Gomes']
  s.email = 'mauricio@edge14.com'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'amatch'
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'actionpack', '< 6.0', '> 4.0'
  s.add_development_dependency 'activesupport', '< 6.0', '> 4.0'
  s.add_development_dependency 'rails', '~> 5'
  s.add_development_dependency 'activeresource'
  s.add_development_dependency 'rest-client', '< 3.0', '>= 2.0'
  s.add_development_dependency 'curb', '~> 0.8.1'
  s.add_development_dependency 'httpi'
  s.add_development_dependency 'faraday', '>= 0.10'
  s.add_development_dependency 'multipart-post', '~> 2.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
