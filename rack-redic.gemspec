# encoding: UTF-8
# frozen_string_literal: true
Gem::Specification.new do |spec|
  spec.name    = 'rack-redic'
  spec.version = '0.9.0'
  spec.authors = ['Evan Lecklider']
  spec.email   = ['evan@lecklider.com']

  spec.summary     = 'Rack::Session in Redis via Redic'
  spec.description = 'Rack::Session in Redis via Redic'
  spec.homepage    = 'https://github.com/evanleck/rack-redic'
  spec.license     = 'MIT'
  spec.files       = `git ls-files`.split("\n")
  spec.test_files  = spec.files.grep(/^spec/)

  spec.add_dependency 'rack'
  spec.add_dependency 'redic'

  spec.add_development_dependency 'msgpack'
  spec.add_development_dependency 'oj'
  spec.add_development_dependency 'rspec'
end
