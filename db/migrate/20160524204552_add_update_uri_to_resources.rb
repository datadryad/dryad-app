class AddUpdateUriToResources < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :update_uri, :string
  end
end
