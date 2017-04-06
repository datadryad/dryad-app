
source 'https://rubygems.org'

gemspec


# TODO: figure out why these are in here instead of/in addition to gemspec
gem 'byebug', group: [:development, :test]
gem 'mysql2', '~> 0.3.20'
gem 'rubocop', require: false, group: [:development, :test]
gem 'simplecov', require: false, group: :test
gem 'responders', '~> 2.0'
gem 'kaminari'
gem 'rubyzip', '>= 1.0.0' # will load new rubyzip version
gem 'parallel_tests', group: [:development, :test]

group :development, :test do
  path '..' do
    gem 'stash_engine'
    gem 'stash_discovery'
  end
end
