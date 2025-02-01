# == Schema Information
#
# Table name: stash_engine_counter_stats
#
#  id                         :integer          not null, primary key
#  citation_count             :integer
#  citation_updated           :datetime         default(2018-01-01 00:00:00.000000000 UTC +00:00)
#  unique_investigation_count :integer
#  unique_request_count       :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  identifier_id              :integer
#
# Indexes
#
#  index_stash_engine_counter_stats_on_identifier_id  (identifier_id)
#
FactoryBot.define do

  factory :counter_stat, class: StashEngine::CounterStat do
    identifier

    citation_count { Faker::Number.number(digits: 1).to_i }
    unique_investigation_count { Faker::Number.number(digits: 4).to_i }
    unique_request_count { Faker::Number.number(digits: 3).to_i }
    citation_updated { Time.now.utc.to_date }
  end
end
