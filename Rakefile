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

# clear rspec/rails default :spec task in favor of :coverage
Rake::Task[:default].clear if Rake::Task.task_defined?(:default)

desc 'Run unit tests, check code style'
task default: %i[spec rubocop]
