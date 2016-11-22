require 'spec_helper'
require 'database_cleaner'

logfile = File.expand_path('log/test.log')
FileUtils.mkdir_p File.dirname(logfile)
ActiveRecord::Base.logger = Logger.new(logfile) if defined?(ActiveRecord::Base)

db_config = YAML.load_file('config/database.yml')['test']

host = db_config['host']
raise("Can't run destructive tests against non-local database #{host}") unless host == 'localhost'

ActiveRecord::Base.establish_connection(db_config)
ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.up 'db/migrate'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
