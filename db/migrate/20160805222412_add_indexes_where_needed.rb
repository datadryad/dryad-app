class AddIndexesWhereNeeded < ActiveRecord::Migration
  def change
    add_index(:stash_engine_identifiers, :identifier)
    add_index(:stash_engine_resource_states, :user_id)
    add_index(:stash_engine_resource_states, :resource_state)
    add_index(:stash_engine_resource_usages, :resource_id)
    add_index(:stash_engine_resources, :identifier_id)
    add_index(:stash_engine_submission_logs, :resource_id)
    add_index(:stash_engine_users, ;email)
    add_index(:stash_engine_users, :uid)
    add_index(:stash_engine_versions, :resource_id)
  end
end
