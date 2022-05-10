class AddImportInfoToStashEngineIdentifier < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_identifiers, :import_info, :integer, default: 0
  end
end
