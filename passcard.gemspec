# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "passcard/version"

Gem::Specification.new do |spec|
  spec.name          = "passcard"
  spec.version       = Passcard::VERSION
  spec.authors       = ["Nikhil Gupta"]
  spec.email         = ["me@nikhgupta.com"]

  spec.summary       = %q{Password Card Generator}
  spec.description   = %q{Password Card Generator}
  spec.homepage      = "https://github.com/nikhgupta/passcard"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "~> 0.20"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
