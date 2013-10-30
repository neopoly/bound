# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bound/version'

Gem::Specification.new do |spec|
  spec.name          = "bound"
  spec.version       = Bound::VERSION
  spec.authors       = ["Jakob Holderbaum", "Jan Owiesniak"]
  spec.email         = ["jh@neopoly.de", "jo@neopoly.de"]
  spec.summary       = %q{Implements a nice helper for fast boundary definitions}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0.7"

  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "benchmark-ips"
end
