# frozen_string_literal: true
Gem::Specification.new do |spec|
  spec.name = 'rack-redic'
  spec.version = '2.1.0'
  spec.authors = ['Evan Lecklider']
  spec.email = ['evan@lecklider.com']

  spec.summary = 'Rack::Session in Redis via Redic'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/evanleck/rack-redic'
  spec.license = 'MIT'
  spec.files = Dir['lib/**/*', 'README.org', 'LICENSE.txt']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_runtime_dependency 'rack', '~> 2'
  spec.add_runtime_dependency 'redic', '~> 1'

  spec.metadata['bug_tracker_uri'] = 'https://github.com/evanleck/rack-redic/issues'
  spec.metadata['changelog_uri'] = 'https://github.com/evanleck/rack-redic/blob/main/CHANGELOG.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = spec.homepage
end
