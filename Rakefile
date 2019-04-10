# ------------------------------------------------------------
# Rails defaults

require File.expand_path('../config/application', __FILE__)
Rails.application.load_tasks

# ------------------------------------------------------------
# Coverage

# desc 'Run all unit tests with coverage'
# task :coverage do
#   ENV['COVERAGE'] = 'true'
#   Rake::Task['spec'].execute
# end

# ------------------------------------------------------------
# RuboCop

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# ------------------------------------------------------------
# Defaults

# clear rspec/rails default :spec task if set already

Rake::Task[:default].clear if Rake::Task.task_defined?(:default)

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |task|
    task.rspec_opts = %w[--color --format documentation --order random]
  end

  task :default do
    # invoke is supposed to only run once
    Rake::Task['rubocop'].invoke
    Rake::Task['spec'].invoke
  end
rescue LoadError
  puts 'There was an error and rspec was not available.'
end
