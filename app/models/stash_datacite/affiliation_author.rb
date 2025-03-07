# frozen_string_literal: true

module StashDatacite
  class AffiliationAuthor < ApplicationRecord
    self.table_name = 'dcs_affiliations_authors'
    has_paper_trail

    belongs_to :affiliations, class_name: 'StashDatacite::Affiliation', foreign_key: 'affiliation_id'
    belongs_to :author, class_name: 'StashEngine::Author', foreign_key: 'author_id'
  end
end
