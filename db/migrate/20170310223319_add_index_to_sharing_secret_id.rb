class AddIndexToSharingSecretId < ActiveRecord::Migration[4.2]
  def change
    add_index :stash_engine_shares, :secret_id, length: 50
  end
end
