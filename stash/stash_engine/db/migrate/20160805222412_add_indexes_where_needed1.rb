class AddIndexesWhereNeeded1 < ActiveRecord::Migration[4.2]
  def change
    add_index(:stash_engine_identifiers, :identifier, length: { identifier: 50 })
    add_index(:stash_engine_resource_states, :user_id)
    add_index(:stash_engine_resource_states, :resource_state)
    add_index(:stash_engine_resource_usages, :resource_id)
    add_index(:stash_engine_resources, :identifier_id)
    add_index(:stash_engine_submission_logs, :resource_id)
    add_index(:stash_engine_users, :email, length: { email: 50 })
    add_index(:stash_engine_users, :uid, length: { uid: 50 })
    add_index(:stash_engine_versions, :resource_id)
  end
end
