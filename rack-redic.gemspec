# frozen_string_literal: true
Gem::Specification.new do |spec|
  spec.name    = 'rack-redic'
  spec.version = '1.4.2'
  spec.authors = ['Evan Lecklider']
  spec.email   = ['evan@lecklider.com']

  spec.summary     = 'Rack::Session in Redis via Redic'
  spec.description = 'Rack::Session in Redis via Redic'
  spec.homepage    = 'https://github.com/evanleck/rack-redic'
  spec.license     = 'MIT'
  spec.files       = `git ls-files`.split("\n")
  spec.test_files  = spec.files.grep(/^test/)

  spec.add_dependency 'rack'
  spec.add_dependency 'redic'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-minitest'
  spec.add_development_dependency 'rubocop-packaging'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rake'
end
