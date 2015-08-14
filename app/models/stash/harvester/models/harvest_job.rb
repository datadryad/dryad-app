require 'active_record'

module Stash
  module Harvester
    module Models
      class HarvestJob < ActiveRecord::Base
        has_many :harvested_records
        has_many :index_jobs

        enum status: STATUSES
      end
    end
  end
end
