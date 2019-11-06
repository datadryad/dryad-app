class RemoveExpirationDateFromShares < ActiveRecord::Migration
  def up
    remove_column :stash_engine_shares, :expiration_date
  end

  def down
    add_column :stash_engine_shares, :expiration_date, :datetime
  end
end
