require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'appraisal'
require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task default: :spec
