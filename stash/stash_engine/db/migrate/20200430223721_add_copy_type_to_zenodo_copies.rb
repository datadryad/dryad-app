class AddCopyTypeToZenodoCopies < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_zenodo_copies, :copy_type, "ENUM('data', 'software', 'software_publish') DEFAULT 'data'"
    add_index :stash_engine_zenodo_copies, :copy_type
    # the resource_id is currently set to be only one, but we need more than one if it handles both data and software copies in this table
    remove_index :stash_engine_zenodo_copies, :resource_id
    add_index :stash_engine_zenodo_copies, :resource_id
  end
end
