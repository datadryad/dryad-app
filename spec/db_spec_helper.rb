require 'factory_girl'
require 'active_record'
require 'stash'

logfile = File.expand_path('log/test.log')
FileUtils.mkdir_p File.dirname(logfile)
ActiveRecord::Base.logger = Logger.new(logfile) if defined?(ActiveRecord::Base)

# ------------------------------------------------------------
# DB-related classes under test

# TODO: Where does this really belong?
db = File.expand_path('db')
$LOAD_PATH.unshift(db) unless $LOAD_PATH.include?(db)

# ------------------------------------------------------------
# SimpleCov setup

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.command_name 'spec:db'

  SimpleCov.minimum_coverage 100
  SimpleCov.start do
    add_group 'db', 'db'
    add_filter '/spec/'
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
    ]
  end
end

# ------------------------------------------------------------
# ActiveRecord setup

connection_info = YAML.load_file('db/config.yml')['test']
ActiveRecord::Base.establish_connection(connection_info)
ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.up 'db/migrate'

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end

# ------------------------------------------------------------
# FactoryGirl configuration

FactoryGirl.find_definitions

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
