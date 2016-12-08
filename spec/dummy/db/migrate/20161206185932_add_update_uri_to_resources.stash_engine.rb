# This migration comes from stash_engine (originally 20160524204552)
class AddUpdateUriToResources < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :update_uri, :string
  end
end
