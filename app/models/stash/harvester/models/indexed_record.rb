require 'active_record'
require_relative 'status'
require_relative 'harvest_job'
require_relative 'index_job'

module Stash
  module Harvester
    module Models
      class IndexedRecord < ActiveRecord::Base
        belongs_to :harvested_record
        belongs_to :index_job

        enum status: STATUSES
      end
    end
  end
end
