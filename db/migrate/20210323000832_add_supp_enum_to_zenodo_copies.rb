class AddSuppEnumToZenodoCopies < ActiveRecord::Migration[5.2]
  def up
    change_column :stash_engine_zenodo_copies, :copy_type, "ENUM('data', 'software', 'software_publish', 'supp', 'supp_publish') DEFAULT 'data'"
  end

  def down
    change_column :stash_engine_zenodo_copies, :copy_type, "ENUM('data', 'software', 'software_publish') DEFAULT 'data'"
  end
end
