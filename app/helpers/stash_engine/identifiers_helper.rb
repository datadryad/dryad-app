module StashEngine
  module IdentifiersHelper

    def can_user_delete_identifier?(identifier)
      identifier.resources.count == 1 &&
        identifier.resources.first.curation_activities.pluck(:status).uniq == ['in_progress']
    end
  end
end
