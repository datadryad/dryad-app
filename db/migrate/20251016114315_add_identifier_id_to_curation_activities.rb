class AddIdentifierIdToCurationActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_curation_activities, :identifier_id, :integer
    add_index :stash_engine_curation_activities, :identifier_id
  end
end
