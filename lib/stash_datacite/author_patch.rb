require 'stash_engine/author'

module StashDatacite
  module AuthorPatch
    def self.patch!
      StashEngine::Author.instance_eval do
        has_and_belongs_to_many :affiliations, class_name: 'StashDatacite::Affiliation', join_table: 'dcs_affiliations_authors'
      end

      StashEngine::Author.class_eval do
        scope :affiliation_filled, -> {
          joins(:affiliations).where <<-SQL
            TRIM(IFNULL(dcs_affiliations.long_name,'')) <> ''
            OR TRIM(IFNULL(dcs_affiliations.short_name,'')) <> ''
          SQL
        }

        #this is to simulate the bad old structure where a user can only have one affiliation
        def affiliation_id=(affil_id)
          affiliations.clear
          self.affiliation_ids = affil_id
        end

        #this is to simulate the bad old structure where a user can only have one affiliation
        def affiliation_id
          affiliation_ids.try(:first)
        end

        #this is to simulate the bad old structure where a user can only have one affiliation
        def affiliation=(affil)
          affiliations.clear
          affiliations << affil
        end

        #this is to simulate the bad old structure where a user can only have one affiliation
        def affiliation
          affiliations.try(:first)
        end
      end
    end
  end
end
