require 'active_record'
require_relative 'status'

module Stash
  module Harvester
    module Models
      class IndexJobs < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        enum status: STATUSES
      end
    end
  end
end
