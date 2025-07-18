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
module StashDatacite
  class AffiliationAuthor < ApplicationRecord
    self.table_name = 'dcs_affiliations_authors'

    belongs_to :affiliation, class_name: 'StashDatacite::Affiliation', foreign_key: 'affiliation_id'
    belongs_to :author, class_name: 'StashEngine::Author', foreign_key: 'author_id'
  end
end
