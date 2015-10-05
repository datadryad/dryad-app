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

  # See https://robots.thoughtbot.com/testing-your-factories-first
  desc 'Ensure FactoryGirl factories produce valid test data'
  RSpec::Core::RakeTask.new(:factories) do |task|
    ENV['COVERAGE'] = nil
    task.pattern = 'factories_spec.rb'
  end

  desc 'Run all database tests'
  RSpec::Core::RakeTask.new(:db) do |task|
    ENV['COVERAGE'] = nil
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = 'db/**/*_spec.rb'
  end

  desc 'Run all application tests'
  RSpec::Core::RakeTask.new(:app) do |task|
    ENV['COVERAGE'] = nil
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = 'app/**/*_spec.rb'
  end

  task all: [:unit, :factories, :db, :app]
end

desc 'Run all tests'
task spec: 'spec:all'

# ------------------------------------------------------------
# Coverage

namespace :coverage do

  desc 'Run all unit tests with coverage'
  task :unit do
    ENV['COVERAGE'] = 'true'
    Rake::Task['spec:unit'].execute
  end

  desc 'Run all application tests with coverage'
  task :app do
    ENV['COVERAGE'] = 'true'
    Rake::Task['spec:app'].execute
  end

  task all: [:unit, :app]
end

desc 'Run all tests with coverage'
task coverage: 'coverage:all'

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

desc 'Run unit tests, check test coverage, run database tests, check code style'
task default: [:coverage, 'spec:db', :rubocop]
