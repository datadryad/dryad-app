class RemoveContainerContentsFromStashEngineGenericFiles < ActiveRecord::Migration[6.1]
  def change
    remove_column :stash_engine_generic_files, :container_contents
  end
end
