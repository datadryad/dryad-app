# ------------------------------------------------------------
# Rails defaults

require File.expand_path('../config/application', __FILE__)
Rails.application.load_tasks

# ------------------------------------------------------------
# Coverage

desc 'Run all unit tests with coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].execute
end

# ------------------------------------------------------------
# RuboCop

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# ------------------------------------------------------------
# Defaults

# # Let's be explicit
# Rake::Task[:default].clear

desc 'Run unit tests, check test coverage, check code style'
task default: %i[coverage rubocop]
