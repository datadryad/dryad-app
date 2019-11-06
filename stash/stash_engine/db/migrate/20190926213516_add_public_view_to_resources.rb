class AddPublicViewToResources < ActiveRecord::Migration
  def change
    # these are for public metadata view and public file view for this version
    add_column :stash_engine_resources, :meta_view, :boolean, default: false
    add_column :stash_engine_resources, :file_view, :boolean, default: false
  end
end
