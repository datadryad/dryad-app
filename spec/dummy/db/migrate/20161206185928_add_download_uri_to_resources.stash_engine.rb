# This migration comes from stash_engine (originally 20160511221433)
class AddDownloadUriToResources < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :download_uri, :string
  end
end
