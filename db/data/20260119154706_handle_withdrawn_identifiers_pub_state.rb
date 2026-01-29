# frozen_string_literal: true

class HandleWithdrawnIdentifiersPubState < ActiveRecord::Migration[8.0]
  def up
    # updated pub_state for withdrawn identifiers
    StashEngine::Identifier.joins(latest_resource: :last_curation_activity).
      where.not(pub_state: 'withdrawn').
      where(last_curation_activity: { status: 'withdrawn' }).each do |identifier|

      PubStateService.new(identifier).update_for_ca_status(identifier.latest_resource.last_curation_activity.status)
    end
  end
end
