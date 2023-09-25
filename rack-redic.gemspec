# frozen_string_literal: true
Gem::Specification.new do |spec|
  spec.name = 'rack-redic'
  spec.version = '2.2.0'
  spec.authors = ['Evan Lecklider']
  spec.email = ['evan@lecklider.com']

  spec.summary = 'Rack::Session in Redis via Redic'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/evanleck/rack-redic'
  spec.license = 'MIT'
  spec.files = Dir['lib/**/*', 'README.md', 'LICENSE.txt']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_runtime_dependency 'rack', '>= 2.0.0', '< 4'
  spec.add_runtime_dependency 'rack-session'
  spec.add_runtime_dependency 'redic', '~> 1'

  spec.metadata['bug_tracker_uri'] = "#{ spec.homepage }/issues"
  spec.metadata['changelog_uri'] = "#{ spec.homepage }/blob/main/CHANGELOG.md"
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = spec.homepage
end
