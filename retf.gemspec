# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'retf'
  s.version     = '0.0.1'
  s.authors     = ['Th3-M4jor']
  s.summary     = 'Ruby ETF encoder/decoder'
  s.description = 'A pure Ruby Erlang ETF encoder/decoder'

  s.required_ruby_version = '>= 3.3.0'

  s.license = 'MIT'
  s.files = ['README.md', 'lib/**/*']
  s.require_paths = ['lib']

  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'rubocop', '~> 1.18'
  s.add_development_dependency 'rubocop-performance', '~> 1.11'
  s.add_development_dependency 'rubocop-rspec', '~> 3.1'
  s.metadata['rubygems_mfa_required'] = 'true'
end
