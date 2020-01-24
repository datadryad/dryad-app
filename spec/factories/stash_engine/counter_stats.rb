FactoryBot.define do

  factory :counter_stat, class: StashEngine::CounterStat do
    identifier

    citation_count { Faker::Number.number(digits: 1).to_i }
    unique_investigation_count { Faker::Number.number(digits: 4).to_i }
    unique_request_count { Faker::Number.number(digits: 3).to_i }
    citation_updated { Date.today }
  end
end
