require 'stash/harvester/models'

FactoryGirl.define do
  # TODO: Find a way to do modules w/o making model class name explicit
  factory :harvest_job, class: Stash::Harvester::Models::HarvestJob do

  end
end
