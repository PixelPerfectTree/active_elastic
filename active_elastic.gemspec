# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_elastic/version'

Gem::Specification.new do |spec|
  spec.name          = "active_elastic"
  spec.version       = ActiveElastic::VERSION
  spec.authors       = ["Briam Santiago", "Marcos Mercedes"]
  spec.email         = ["briam@pixept.com", "marcos@pixelpt.com"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = %q{ActiveElastic grants to an ActiveRecord models to query and index documents easily to ElasticSearch.}
  spec.description   = %q{ActiveElastic grants to an ActiveRecord models to query and index documents easily to ElasticSearch.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'elasticsearch-model'
  spec.add_dependency 'elasticsearch-rails'
  spec.add_dependency 'elasticsearch-persistence'
  spec.add_dependency 'sidekiq'

  spec.add_development_dependency "activemodel", "~> 4"
  spec.add_development_dependency "activesupport", "~> 4"
  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
