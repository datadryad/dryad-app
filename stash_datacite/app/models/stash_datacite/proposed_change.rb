module StashEngine
  class ProposedChange < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier', foreign_key: 'identifier_id'
    belongs_to :user, class_name: 'StashEngine::User', foreign_key: 'user_id'

    def approve!(current_user:)
      return false unless current_user.is_a?(StashEngine::User)

      cr = Stash::Import::Crossref.from_proposed_change(proposed_change: self)
      resource = cr.populate_resource
      resource.save
      resource.identifier.save
      update(approved: true, user_id: current_user.id)
      true
    end

    def reject!
      destroy
    end
  end
end
