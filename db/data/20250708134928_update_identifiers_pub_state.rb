# frozen_string_literal: true

class UpdateIdentifiersPubState < ActiveRecord::Migration[8.0]
  def up
    Rails.logger.level = Logger::DEBUG
    # updated pub_state for wrong withdrawn state values
    StashEngine::Identifier.joins(latest_resource: :last_curation_activity).
      where(pub_state: 'withdrawn').
      where.not(stash_engine_curation_activities: {status: 'withdrawn'}).each do |identifier|

      PubStateService.new(identifier).update_for_ca_status(identifier.latest_resource.last_curation_activity.status)
    end

    # updated pub_state for nil state values
    StashEngine::Identifier.includes(resources: :curation_activities).
      where(pub_state: nil).each do |identifier|

      PubStateService.new(identifier).update_from_history
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
