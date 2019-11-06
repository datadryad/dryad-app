class ChangeResourcesInternalData < ActiveRecord::Migration
  def change
    rename_column :stash_engine_internal_data, :resource_id, :identifier_id
  end
end
