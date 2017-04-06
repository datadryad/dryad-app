require 'active_record'
require 'models/status'
require 'models/harvest_job'

module Stash
  module Harvester
    module Models
      class IndexJob < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        enum status: Status::ALL
      end
    end
  end
end
