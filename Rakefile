# ------------------------------------------------------------
# Rails defaults

require File.expand_path('config/application', __dir__)
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
  puts 'Running main rspec tasks...'
  puts " -- environment #{ENV.fetch('RAILS_ENV', nil)}"
  RSpec::Core::RakeTask.new(:spec) do |task|
    task.rspec_opts = %w[--color --format documentation --order random --require rails_helper]
  end

  task default: %i[rubocop spec]
rescue LoadError
  puts 'There was an error and rspec was not available.'
end
