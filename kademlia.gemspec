# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kademlia/version'

Gem::Specification.new do |spec|
  spec.name          = "kademlia"
  spec.version       = Kademlia::VERSION
  spec.authors       = ["Gabriel Hartmann"]
  spec.email         = ["gabriel.hartmann@gmail.com"]
  spec.summary       = %q{Write a short summary. Required.}
  spec.description   = %q{Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "bencode", "~> 0.8.2"
  spec.add_development_dependency "workflow", "~> 1.2.0"
  spec.add_development_dependency "mono_logger", "~> 1.1.0"
end
