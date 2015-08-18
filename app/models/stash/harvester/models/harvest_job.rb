require 'active_record'
require_relative 'status'

# TODO: Add validations to all models http://guides.rubyonrails.org/active_record_validations.html

module Stash
  module Harvester
    module Models
      class HarvestJob < ActiveRecord::Base
        has_many :harvested_records
        has_many :index_jobs

        enum status: Status::ALL
      end
    end
  end
end
