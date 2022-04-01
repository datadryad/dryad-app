class AddDownloadUriToResources < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :download_uri, :string
  end
end
