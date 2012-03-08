# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{api-auth}
  s.summary = %q{Simple HMAC authentication for your APIs}
  s.description = %q{Full HMAC auth implementation for use in your gems and Rails apps.}
  s.homepage = %q{http://github.com/geminisbs/api-auth}
  s.version = File.read(File.join(File.dirname(__FILE__), 'VERSION'))
  s.authors = ["Mauricio Gomes"]
  s.email = "mauricio@edge14.com"

  s.add_development_dependency "rspec", "~> 2.4.0"
  s.add_development_dependency "amatch", "~> 0.2.10"
  s.add_development_dependency "actionpack", "~> 2.3.2"
  s.add_development_dependency "activesupport", "~> 2.3.2"
  s.add_development_dependency "activeresource", "~> 2.3.2"
  s.add_development_dependency "rest-client", "~> 1.6.0"
  s.add_development_dependency "curb", "~> 0.7.7"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
