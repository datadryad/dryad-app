class AddDigestIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :stash_engine_generic_files, [:type, :digest]
  end
end
