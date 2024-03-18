class AddStorageVersionId < ActiveRecord::Migration[6.1]
  def change
     add_column :stash_engine_generic_files, :storage_version_id, :integer, after: :resource_id
  end
end
