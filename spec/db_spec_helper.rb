require 'spec_helper'

require 'stash/harvester/models/models'

connection_info = YAML.load_file('db/config.yml')['test']
ActiveRecord::Base.establish_connection(connection_info)

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      fail ActiveRecord.Rollback
    end
  end
end
