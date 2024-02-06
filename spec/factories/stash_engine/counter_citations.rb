# == Schema Information
#
# Table name: stash_engine_counter_citations
#
#  id            :integer          not null, primary key
#  citation      :text(65535)
#  doi           :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#
# Indexes
#
#  index_stash_engine_counter_citations_on_doi            (doi)
#  index_stash_engine_counter_citations_on_identifier_id  (identifier_id)
#
FactoryBot.define do

  factory :counter_citation, class: StashEngine::CounterCitation do
    identifier

    citation { Faker::Lorem.sentence }
    doi { identifier { "https://doi.org/#{Faker::Pid.doi}" } }
  end
end
