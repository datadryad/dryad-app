class RemoveIdentifierIdFromStashEngineCurationActivities < ActiveRecord::Migration[4.2]
  def change
    remove_column :stash_engine_curation_activities, :identifier_id
  end
end
