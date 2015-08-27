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

  # See https://robots.thoughtbot.com/testing-your-factories-first
  desc 'Ensure FactoryGirl factories produce valid test data'
  RSpec::Core::RakeTask.new(:factories) do |task|
    ENV['COVERAGE'] = nil
    task.pattern = 'factories_spec.rb'
  end

  desc 'Run all model tests'
  RSpec::Core::RakeTask.new(:models) do |task|
    Rake::Task['spec:factories'].invoke

    ENV['COVERAGE'] = nil
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = 'models/**/*_spec.rb'
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
# Database

require 'standalone_migrations'
StandaloneMigrations::Tasks.load_tasks

# ------------------------------------------------------------
# Miscellaneous

task :debug_load_path do
  puts $LOAD_PATH
end

# ------------------------------------------------------------
# Defaults

desc 'Run unit tests, check test coverage, run acceptance tests, check code style'
task default: [:coverage, 'spec:acceptance', :rubocop]
