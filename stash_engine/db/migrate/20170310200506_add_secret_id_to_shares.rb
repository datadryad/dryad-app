class AddSecretIdToShares < ActiveRecord::Migration
  def up
    add_column :stash_engine_shares, :secret_id, :string, after: :sharing_link
    # transform data from old to new column
    StashEngine::Share.reset_column_information
    StashEngine::Share.all.each do |s|
      s.update_column(:secret_id, s.sharing_link.match(/^https+\:\/\/\S+\/stash\/share\/(\S+)/)[1]) if s.sharing_link && s.secret_id.nil?
    end
  end

  def down
    remove_column :stash_engine_shares, :secret_id
    # really can't transform data down
  end
end
