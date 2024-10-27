# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'retf'
  s.version     = '0.0.2'
  s.authors     = ['Th3-M4jor']
  s.summary     = 'Ruby ETF encoder/decoder'
  s.description = 'A pure Ruby Erlang ETF encoder/decoder'

  s.required_ruby_version = '>= 3.2.0'

  s.license = 'MIT'
  s.files = ['README.md', 'lib/**/*']
  s.require_paths = ['lib']

  s.extensions = ['ext/retf/extconf.rb']

  s.add_development_dependency 'benchmark-ips', '~> 2.9'
  s.add_development_dependency 'msgpack', '~> 1.7'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rake-compiler', '~> 1.2'
  s.add_development_dependency 'rspec', '~> 3.10'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-performance'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'rubocop-thread_safety'
  s.metadata['rubygems_mfa_required'] = 'true'
end
