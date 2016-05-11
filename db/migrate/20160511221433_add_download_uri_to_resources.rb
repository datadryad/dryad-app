class AddDownloadUriToResources < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :download_uri, :string
  end
end
