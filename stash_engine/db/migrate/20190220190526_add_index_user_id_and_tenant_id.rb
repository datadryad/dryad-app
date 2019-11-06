class AddIndexUserIdAndTenantId < ActiveRecord::Migration
  def change
    # I think it would be good to index these for finding resources by users or tenant quickly, probably
    # most foreign keys could be indexed by default
    add_index :stash_engine_resources, :user_id
    add_index :stash_engine_resources, :tenant_id
  end
end
