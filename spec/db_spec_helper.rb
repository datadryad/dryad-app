require 'spec_helper'
require 'active_record'
require 'rspec-activerecord'

# TODO: put this somewhere else?
models = File.expand_path('app')
$LOAD_PATH.unshift(models) unless $LOAD_PATH.include?(models)

require 'models/stash/harvester/models'

connection_info = YAML.load_file('db/config.yml')['test']
ActiveRecord::Base.establish_connection(connection_info)

ActiveRecord::Migrator.up 'db/migrate'

RSpec.configure do |config|

  config.use_transactional_fixtures = true

  config.before :each do |example|
    fixture = example.metadata[:fixture]
    config.fixture_path = File.expand_path("spec/fixtures/#{fixture}")
  end

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      fail ActiveRecord.Rollback
    end
  end
end
