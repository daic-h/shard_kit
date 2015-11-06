# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sharding_kit/version"

Gem::Specification.new do |spec|
  spec.name          = "sharding_kit"
  spec.version       = ShardingKit::VERSION
  spec.authors       = ["Daichi HIRATA"]
  spec.email         = ["hirata.daichi@gmail.com"]
  spec.summary       = "Write a short summary. Required."
  spec.description   = "Write a longer description. Optional."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.0.0"
  spec.add_dependency "activesupport", ">= 4.0.0"

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "mysql2", "~> 0.3.20"
  # spec.add_development_dependency 'pg', '>= 0.11.0'
  spec.add_development_dependency "rspec", ">= 3"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "pry-byebug"
end
