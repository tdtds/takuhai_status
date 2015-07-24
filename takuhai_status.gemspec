# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'takuhai_status/version'

Gem::Specification.new do |spec|
  spec.name          = "takuhai_status"
  spec.version       = TakuhaiStatus::VERSION
  spec.authors       = ["TADA Tadashi"]
  spec.email         = ["t@tdtds.jp"]

  spec.summary       = %q{get delivery status of Takuhai-bin in Japan}
  spec.description   = %q{get delivery status of Takuhai-bin in Japan}
  spec.homepage      = "https://github.com/tdtds/takuhai_status"
  spec.license       = "GPL"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "faraday"
  spec.add_runtime_dependency "mechanize"
  spec.add_runtime_dependency "faraday-cookie_jar"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
