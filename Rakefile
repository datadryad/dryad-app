begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'StashDatacite'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path('../spec/dummy/Rakefile', __FILE__)
load 'rails/tasks/engine.rake'
load 'rails/tasks/statistics.rake'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
t.pattern = Dir.glob('spec/**/*_spec.rb')
t.rspec_opts = '--format documentation'
# t.rspec_opts << ' more options'
end
task :default => :spec