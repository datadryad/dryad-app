class AddUpdateUriToResources < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :update_uri, :string
  end
end
