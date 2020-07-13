class ChangeResourcesInternalData < ActiveRecord::Migration[4.2]
  def change
    rename_column :stash_engine_internal_data, :resource_id, :identifier_id
  end
end
