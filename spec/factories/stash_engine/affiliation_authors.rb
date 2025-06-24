# frozen_string_literal: true

# == Schema Information
#
# Table name: dcs_affiliations_authors
#
#  id             :integer          not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  affiliation_id :integer
#  author_id      :integer
#
# Indexes
#
#  index_dcs_affiliations_authors_on_affiliation_id  (affiliation_id)
#  index_dcs_affiliations_authors_on_author_id       (author_id)
#
FactoryBot.define do

  factory :affiliation_author, class: StashDatacite::AffiliationAuthor do
    association :author, factory: :author
    association :affiliation, factory: :affiliation
  end
end
