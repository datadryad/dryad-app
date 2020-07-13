class RemoveSharingLinkFromShares < ActiveRecord::Migration[4.2]
  def up
    remove_column :stash_engine_shares, :sharing_link
  end

  def down
    add_column :stash_engine_shares, :sharing_link, :string
  end
end
