class AddCompressedTriesToGenericFiles < ActiveRecord::Migration[6.1]
  def change
    add_column :stash_engine_generic_files, :compressed_try, :integer, default: 0
  end
end
