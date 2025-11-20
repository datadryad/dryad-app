class AddIndexesOnStashEngineRepoQueueStates < ActiveRecord::Migration[8.0]
  def change
    add_index :stash_engine_repo_queue_states, :state
  end
end
