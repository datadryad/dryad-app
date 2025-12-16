# frozen_string_literal: true

class RemoveWithdrawnFundingUpdaterRecords < ActiveRecord::Migration[8.0]
  def up
    RecordUpdater.pending.where(record_type: "StashDatacite::Contributor")
      .joins('inner join dcs_contributors on record_id = dcs_contributors.id')
      .joins('inner join stash_engine_resources on stash_engine_resources.id = dcs_contributors.resource_id')
      .joins('INNER JOIN stash_engine_curation_activities ON stash_engine_curation_activities.id = stash_engine_resources.last_curation_activity_id and stash_engine_curation_activities.status="withdrawn"')
      .delete_all
  end

  def down
  end
end
