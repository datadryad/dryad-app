require 'models'

FactoryGirl.define do
  # TODO: Find a way to do modules w/o making model class name explicit
  factory :index_job, class: Stash::Harvester::Models::IndexJob do

  end
end
