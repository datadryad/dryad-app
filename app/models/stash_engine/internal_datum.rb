# == Schema Information
#
# Table name: stash_engine_internal_data
#
#  id            :integer          not null, primary key
#  data_type     :string(191)
#  value         :string(191)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#
# Indexes
#
#  index_stash_engine_internal_data_on_data_type_and_value  (data_type,value)
#  index_stash_engine_internal_data_on_identifier_id        (identifier_id)
#
module StashEngine
  class InternalDatum < ApplicationRecord
    self.table_name = 'stash_engine_internal_data'
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: :identifier_id
    belongs_to :journal_issn, class_name: 'StashEngine::JournalIssn', foreign_key: :value, optional: true
    belongs_to :manuscripts, class_name: 'StashEngine::Manuscript', primary_key: :manuscript_number, foreign_key: :value, optional: true
    validates :data_type, inclusion: {
      in: %w[manuscriptNumber mismatchedDOI duplicateItem formerManuscriptNumber publicationISSN
             publicationName pubmedID dansArchiveDate dansEditIRI],
      message: '%{value} is not a valid data type'
    }
    validates :data_type, presence: true
    validates :value, presence: true

    def self.data_type(type)
      where('data_type = ?', type)
    end

    def self.allows_multiple(type)
      case type
      when 'mismatchedDOI', 'duplicateItem', 'formerManuscriptNumber'
        true
      else
        false
      end
    end
  end
end
