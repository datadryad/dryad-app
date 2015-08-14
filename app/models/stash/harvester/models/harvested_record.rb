require 'active_record'
require_relative 'status'

module Stash
  module Harvester
    module Models
      class HarvestedRecord < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        # TODO: test me
        def self.find_last_indexed
          joins(:indexed_records).where(status: :completed).order(timestamp: :desc).first
        end

        # TODO: test me
        def self.find_first_failed
          joins(:indexed_records).where(status: :failed).order(:timestamp).last
        end
      end
    end
  end
end
