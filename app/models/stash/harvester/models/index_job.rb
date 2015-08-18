require 'active_record'
require_relative 'status'
require_relative 'harvest_job'

module Stash
  module Harvester
    module Models
      class IndexJob < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        enum status: STATUSES
      end
    end
  end
end
