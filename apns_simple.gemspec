# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apns_simple/version'

Gem::Specification.new do |spec|
  spec.name          = "apns_simple"
  spec.version       = ApnsSimple::VERSION
  spec.authors       = ["Andrey Voronkov"]
  spec.email         = ["andrey.voronkov@medm.com"]

  spec.summary       = %q{Simple Apple Push Notifications sender}
  spec.description   = %q{Simple Apple Push Notifications sender}
  spec.homepage      = "https://github.com/Antiarchitect/apns_simple"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
