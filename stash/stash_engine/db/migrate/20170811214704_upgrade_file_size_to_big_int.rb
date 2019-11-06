class UpgradeFileSizeToBigInt < ActiveRecord::Migration
  def up
    change_column :stash_engine_file_uploads, :upload_file_size, :integer, limit: 8 # make bigint
  end

  def down
    change_column :stash_engine_file_uploads, :upload_file_size, :integer, limit: 4 # regular int
  end
end
