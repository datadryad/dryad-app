class AddDownloadUriToResources < ActiveRecord::Migration
  def change
    add_column :resources, :download_uri, :string
  end
end
