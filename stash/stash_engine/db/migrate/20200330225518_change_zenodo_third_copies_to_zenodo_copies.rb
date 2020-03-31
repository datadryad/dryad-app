class ChangeZenodoThirdCopiesToZenodoCopies < ActiveRecord::Migration
  def change
    rename_table :stash_engine_zenodo_third_copies, :stash_engine_zenodo_copies
  end
end
