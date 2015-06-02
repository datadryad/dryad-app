# ------------------------------------------------------------
# RSpec

require 'rspec/core'
require 'rspec/core/rake_task'

namespace :spec do

  desc 'Run all unit tests'
  RSpec::Core::RakeTask.new(:unit) do |task|
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = 'unit/**/*_spec.rb'
  end

  desc 'Run all acceptance tests'
  RSpec::Core::RakeTask.new(:acceptance) do |task|
    ENV['COVERAGE'] = nil
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = 'acceptance/**/*_spec.rb'
  end

  task all: [:unit, :acceptance]
end

desc 'Run all tests'
task spec: 'spec:all'

# ------------------------------------------------------------
# Coverage

desc 'Run all unit tests with coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec:unit'].execute
end

# ------------------------------------------------------------
# RuboCop

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# ------------------------------------------------------------
# TODOs

desc 'List TODOs (from spec/todo.rb)'
RSpec::Core::RakeTask.new(:todo) do |task|
  task.rspec_opts = %w(--color --format documentation --order default)
  task.pattern = 'todo.rb'
end

# ------------------------------------------------------------
# Defaults

desc 'Run unit tests, check test coverage, run acceptance tests, check code style'
task default: [:coverage, 'spec:acceptance', :rubocop]
