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

task default: %i[compile spec]

Rake.add_rakelib('fuzzing')
