class RemoveExpirationDateFromShares < ActiveRecord::Migration[4.2]
  def up
    remove_column :stash_engine_shares, :expiration_date
  end

  def down
    add_column :stash_engine_shares, :expiration_date, :datetime
  end
end
