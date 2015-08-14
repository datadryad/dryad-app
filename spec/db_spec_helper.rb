require 'spec_helper'
require 'app/models/stash/harvester/models'

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
