FactoryBot.define do

  factory :counter_citation, class: StashEngine::CounterCitation do
    identifier

    citation { Faker::Lorem.sentence }
    doi { identifier { "https://doi.org/#{Faker::Pid.doi}" } }
  end
end
