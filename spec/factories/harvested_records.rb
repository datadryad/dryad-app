require 'models'

FactoryGirl.define do
  # TODO: Find a way to do modules w/o making model class name explicit
  factory :harvested_record, class: Stash::Harvester::Models::HarvestedRecord do

  end
end
