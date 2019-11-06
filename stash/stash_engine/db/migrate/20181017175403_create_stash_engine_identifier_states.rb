# This table is just to find the current curation status for a particular identifier.

class CreateStashEngineIdentifierStates < ActiveRecord::Migration
  def change
    create_table :stash_engine_identifier_states do |t|
      t.integer :identifier_id
      t.integer :curation_activity_id
      t.string :current_curation_status
    end
  end
end
