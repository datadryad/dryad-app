# ------------------------------------------------------------
# Rails defaults

require File.expand_path('../config/application', __FILE__)
Rails.application.load_tasks

# ------------------------------------------------------------
# RuboCop

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# ------------------------------------------------------------
# Defaults

# clear rspec/rails default :spec task if set already

Rake::Task[:default].clear if Rake::Task.task_defined?(:default)
Rake::Task[:spec].clear if Rake::Task.task_defined?(:spec)

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |task|
    task.rspec_opts = %w[--color --format documentation --order random]
  end

  task default: %i[db:migrate rubocop spec]
rescue LoadError
  puts 'There was an error and rspec was not available.'
end
