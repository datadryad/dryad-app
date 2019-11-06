class ModifyResourceStatesResourceStateEnum < ActiveRecord::Migration
  def up
    change_table :stash_engine_resource_states do |t|
      t.change :resource_state, "ENUM('in_progress', 'processing', 'published', 'error', 'embargoed', 'submitted', 'revised', 'deleted' ) DEFAULT 'in_progress'"
      StashEngine::ResourceState.connection.execute(
        "UPDATE stash_engine_resource_states SET resource_state = 'published' WHERE resource_state = 'submitted'"
      )
      t.change :resource_state, "ENUM('in_progress', 'processing', 'published', 'error', 'embargoed' ) DEFAULT 'in_progress'"
    end
  end

  def down
    t.change :resource_state, "ENUM('in_progress', 'processing', 'published', 'error', 'embargoed', 'submitted' ) DEFAULT 'in_progress'"
    StashEngine::ResourceState.connection.execute(
      "UPDATE stash_engine_resource_states SET resource_state = 'submitted' WHERE resource_state = 'published' or resource_state = 'processing'"
    )
    t.change :resource_state, "ENUM('in_progress', 'submitted', 'revised', 'deleted' ) DEFAULT 'in_progress'"
  end
end
