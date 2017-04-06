class RemoveSharingLinkFromShares < ActiveRecord::Migration
  def up
    remove_column :stash_engine_shares, :sharing_link
  end

  def down
    add_column :stash_engine_shares, :sharing_link, :string
  end
end
