class AddSoftwareDoiToZenodoCopies < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_zenodo_copies, :software_doi, :string
    add_index :stash_engine_zenodo_copies, :software_doi
  end
end
