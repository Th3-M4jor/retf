# frozen_string_literal: true

require 'rake/extensiontask'
require 'rspec/core'
require 'rspec/core/rake_task'

Rake::ExtensionTask.new('retf_native') do |ext|
  ext.lib_dir = 'lib/retf'
end

task spec: :compile

# Define the "spec" task, at task load time rather than inside another task
RSpec::Core::RakeTask.new(:spec)

desc 'Run all tests, even those usually excluded.'
task all_tests: :environment do
  ENV['RUN_ALL_TESTS'] = 'true'
  Rake::Task['spec'].invoke
end

task default: %i[compile spec]
