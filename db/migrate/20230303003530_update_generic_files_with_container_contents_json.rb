class UpdateGenericFilesWithContainerContentsJson < ActiveRecord::Migration[6.1]
  def change
    add_column :stash_engine_generic_files, :container_contents, :json
  end
end
