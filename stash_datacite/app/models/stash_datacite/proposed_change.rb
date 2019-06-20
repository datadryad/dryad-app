module StashDatacite
  class ProposedChange < ActiveRecord::Base
    belongs_to :stash_identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :approved_by, class_name: 'StashEngine::User', foreign_key: 'approved_by_id'

    def approve
      # TODO: Logic to update the associated dataset with this model's values
    end

    def reject
      # TODO: Toggle boolean
    end
  end
end
