# ------------------------------------------------------------
# Rails

require 'bundler/gem_tasks'

begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

APP_RAKEFILE = File.expand_path('../spec/dummy/Rakefile', __FILE__)
load 'rails/tasks/engine.rake'

Bundler::GemHelper.install_tasks

Dir[File.join(File.dirname(__FILE__), 'tasks/**/*.rake')].each { |f| load f }

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
    task.rspec_opts = %w(--color --format documentation --order default)
    task.pattern = 'acceptance/**/*_spec.rb'
  end

  # TODO: separate DB and non-DB specs
  # RSpec::Core::RakeTask.new(spec: 'app:db:test:prepare') do |task|
  #   task.rspec_opts = %w(--color --format documentation --order default)
  # end

  task all: [:unit, :acceptance]
end

desc 'Run all tests'
task spec: 'spec:all'

# ------------------------------------------------------------ 
# Defaults  

task default: :spec
