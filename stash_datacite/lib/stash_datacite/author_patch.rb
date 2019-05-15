module StashDatacite
  # Ensure Author-Affiliation relation & related methods
  # invoked from StashDatacite::Resource::Completions when first needed
  module AuthorPatch

    def self.patch!
      StashEngine::Author.instance_eval do
        has_and_belongs_to_many :affiliations, class_name: 'StashDatacite::Affiliation', join_table: 'dcs_affiliations_authors'

        accepts_nested_attributes_for :affiliations
      end

      # The join allows for a many to many relationship between authors and affiliations
      # but the UI only allows for one affiliation. It would be better to refactor the
      # relationship and drop the join table but simply adding these helper methods will
      # allow us to treat it as a one-one relationship for MVP
      StashEngine::Author.class_eval do

        def affiliation
          affiliations.order(created_at: :asc).first
        end

        def affiliation=(affil)
          return unless affil.is_a?(StashDatacite::Affiliation)
          affiliations.destroy_all
          affiliations << affil
        end

      end
    end

  end
end
