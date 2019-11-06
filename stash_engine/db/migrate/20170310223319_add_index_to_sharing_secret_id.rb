class AddIndexToSharingSecretId < ActiveRecord::Migration
  def change
    add_index :stash_engine_shares, :secret_id, length: 50
  end
end
