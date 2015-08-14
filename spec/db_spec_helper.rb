require 'spec_helper'
require 'rspec/rails/fixture_support'
require 'rspec/rails/active_record'

# TODO: put this somewhere else?
models = File.expand_path('app')
$LOAD_PATH.unshift(models) unless $LOAD_PATH.include?(models)

require 'models/stash/harvester/models'

connection_info = YAML.load_file('db/config.yml')['test']
ActiveRecord::Base.establish_connection(connection_info)

ActiveRecord::Migrator.up 'db/migrate'

RSpec.configure do |config|

  # Limited subset of rspec/rails/configuration
  config.add_setting :fixture_path
  config.include RSpec::Rails::FixtureSupport, :use_fixtures

  config.fixture_path = File.expand_path('spec/fixtures')
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      fail ActiveRecord.Rollback
    end
  end
end
