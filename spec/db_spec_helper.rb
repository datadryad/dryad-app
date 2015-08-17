require 'spec_helper'
require 'factory_girl'
require 'active_record'

# ------------------------------------------------------------
# Model classes under test

# TODO: Where does this really belong?
models = File.expand_path('app/models')
$LOAD_PATH.unshift(models) unless $LOAD_PATH.include?(models)

require 'stash/harvester/models'

# ------------------------------------------------------------
# ActiveRecord setup

connection_info = YAML.load_file('db/config.yml')['test']
ActiveRecord::Base.establish_connection(connection_info)
ActiveRecord::Migrator.up 'db/migrate'

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      fail ActiveRecord::Rollback
    end
  end
end

# ------------------------------------------------------------
# FactoryGirl configuration

FactoryGirl.find_definitions

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
