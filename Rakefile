# ------------------------------------------------------------
# Rails defaults

require File.expand_path('../config/application', __FILE__)
Rails.application.load_tasks

task default: [:about]

# ------------------------------------------------------------
# Coverage

desc 'Run all unit tests with coverage'
task :coverage do
  require 'simplecov'
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].execute
end

# ------------------------------------------------------------
# RuboCop

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# ------------------------------------------------------------
# Defaults

# clear rspec/rails default :spec task in favor of :coverage
Rake::Task[:default].clear

# desc 'Run unit tests, check test coverage, check code style'
# task default: %i[coverage rubocop]

desc 'Run unit tests, check code style'
task default: %i[spec rubocop]
