module StashEngine
  class InternalDatum < ApplicationRecord
    self.table_name = 'stash_engine_internal_data'
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
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
