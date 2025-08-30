# == Schema Information
#
# Table name: stash_engine_proposed_changes
#
#  id               :integer          not null, primary key
#  approved         :boolean
#  authors          :text(65535)
#  provenance       :string(191)
#  provenance_score :float(24)
#  publication_date :datetime
#  publication_doi  :string(191)
#  publication_issn :string(191)
#  publication_name :string(191)
#  rejected         :boolean
#  score            :float(24)
#  subjects         :text(65535)
#  title            :text(65535)
#  url              :string(191)
#  xref_type        :string(191)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  identifier_id    :integer
#  user_id          :integer
#
# Indexes
#
#  index_stash_engine_proposed_changes_on_identifier_id     (identifier_id)
#  index_stash_engine_proposed_changes_on_publication_doi   (publication_doi)
#  index_stash_engine_proposed_changes_on_publication_issn  (publication_issn)
#  index_stash_engine_proposed_changes_on_publication_name  (publication_name)
#  index_stash_engine_proposed_changes_on_user_id           (user_id)
#
FactoryBot.define do

  factory :proposed_change, class: StashEngine::ProposedChange do
    identifier
    approved { false }
    rejected { false }
    xref_type { 'journal-article' }
    provenance { 'crossref' }
    provenance_score { Faker::Number.decimal }
    score { Faker::Number.decimal }
    publication_date { Time.now.utc.to_date - 1.month }
    publication_doi { Faker::Pid.doi }
    publication_name { Faker::Company.unique.industry }
    publication_issn { "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}" }
    title { Faker::Hipster.sentence }
    authors { 3.times.map { { ORCID: Faker::Pid.orcid, given: Faker::Name.first_name, family: Faker::Name.last_name } }.to_json }

    trait :preprint do
      xref_type { 'posted-content' }
    end

  end

end
