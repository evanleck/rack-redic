# frozen_string_literal: true
Gem::Specification.new do |spec|
  spec.name = 'rack-redic'
  spec.version = '2.0.1'
  spec.authors = ['Evan Lecklider']
  spec.email = ['evan@lecklider.com']

  spec.summary = 'Rack::Session in Redis via Redic'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/evanleck/rack-redic'
  spec.license = 'MIT'
  spec.files = Dir['lib/**/*', 'README.org', 'LICENSE.txt']
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/evanleck/rack-redic/issues',
    'source_code_uri' => spec.homepage
  }

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
