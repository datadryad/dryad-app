require 'active_record'
require 'models/status'
require 'models/harvest_job'
require 'models/index_job'

module Stash
  module Harvester
    module Models
      class IndexedRecord < ActiveRecord::Base
        belongs_to :harvested_record
        belongs_to :index_job

        enum status: Status::ALL
      end
    end
  end
end
