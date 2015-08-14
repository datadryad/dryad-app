require 'spec_helper'

# TODO: something cleaner
models = File.expand_path('../../app/models', __FILE__)
$LOAD_PATH.unshift(models) unless $LOAD_PATH.include?(models)

require 'stash/harvester/models'

connection_info = YAML.load_file('db/config.yml')['test']
ActiveRecord::Base.establish_connection(connection_info)

ActiveRecord::Migrator.up 'db/migrate'

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      fail ActiveRecord.Rollback
    end
  end
end
