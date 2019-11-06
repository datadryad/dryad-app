class RemoveIdentifierIdFromStashEngineCurationActivities < ActiveRecord::Migration
  def change
    remove_column :stash_engine_curation_activities, :identifier_id
  end
end
