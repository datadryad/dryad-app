# == Schema Information
#
# Table name: stash_engine_counter_stats
#
#  id                         :integer          not null, primary key
#  identifier_id              :integer
#  citation_count             :integer
#  unique_investigation_count :integer
#  unique_request_count       :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  citation_updated           :datetime         default(Mon, 01 Jan 2018 00:00:00.000000000 UTC +00:00)
#
FactoryBot.define do

  factory :counter_stat, class: StashEngine::CounterStat do
    identifier

    citation_count { Faker::Number.number(digits: 1).to_i }
    unique_investigation_count { Faker::Number.number(digits: 4).to_i }
    unique_request_count { Faker::Number.number(digits: 3).to_i }
    citation_updated { Date.today }
  end
end
