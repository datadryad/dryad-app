require 'stash/harvester/models'

FactoryGirl.define do
  # TODO: Find a way to do modules w/o making model class name explicit
  factory :indexed_record, class: Stash::Harvester::Models::IndexedRecord do

  end
end
