# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-buffer-lightening"
  spec.version       = "0.0.0"
  spec.authors       = ["TAGOMORI Satoshi"]
  spec.email         = ["tagomoris@gmail.com"]
  spec.description   = %q{Fluentd memory buffer plugin with msec flush intervals and many types of chunk limits}
  spec.summary       = %q{Alternative memory buffer plugin for Fluentd}
  spec.homepage      = "https://github.com/tagomoris/fluent-plugin-buffer-lightening"
  spec.license       = "APLv2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "fluentd"
end
