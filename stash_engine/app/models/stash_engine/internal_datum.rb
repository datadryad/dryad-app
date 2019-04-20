module StashEngine
  class InternalDatum < ActiveRecord::Base
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    validates :data_type, inclusion: { in: %w[manuscriptNumber mismatchedDOI duplicateItem formerManuscriptNumber publicationISSN
          publicationDOI pubmedID], message: '%{value} is not a valid data type' }
    validates :data_type, presence: true
    validates :value, presence: true

    def self.data_type(type)
      where('data_type = ?', type)
    end

    def self.allows_multiple(type)
      case type
      when 'manuscriptNumber', 'publicationISSN', 'publicationDOI', 'pubmedID'
        false
      when 'mismatchedDOI', 'duplicateItem', 'formerManuscriptNumber'
        true
      else
        false
      end
    end
  end
end
