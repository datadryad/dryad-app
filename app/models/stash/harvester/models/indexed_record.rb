require 'active_record'
require_relative 'status'

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
