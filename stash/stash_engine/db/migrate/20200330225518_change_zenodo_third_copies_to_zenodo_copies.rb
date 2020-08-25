class ChangeZenodoThirdCopiesToZenodoCopies < ActiveRecord::Migration[4.2]
  def change
    rename_table :stash_engine_zenodo_third_copies, :stash_engine_zenodo_copies
  end
end
