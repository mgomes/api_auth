# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{api-auth}
  s.summary = %q{Simple HMAC authentication for your APIs}
  s.description = %q{Full HMAC auth implementation for use in your gems and Rails apps.}
  s.homepage = %q{https://github.com/mgomes/api_auth}
  s.version = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.authors = ["Mauricio Gomes"]
  s.email = "mauricio@edge14.com"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "rake"
  s.add_development_dependency "amatch"
  s.add_development_dependency "rspec", "~> 2.4.0"
  s.add_development_dependency "actionpack", "~> 3.0.0"
  s.add_development_dependency "activesupport", "~> 3.0.0"
  s.add_development_dependency "activeresource", "~> 3.0.0"
  s.add_development_dependency "rest-client", "~> 1.6.0"
  s.add_development_dependency "curb", "~> 0.8.1"
  s.add_development_dependency "httpi"
  s.add_development_dependency "faraday"
  s.add_development_dependency "multipart-post", "~> 2.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
