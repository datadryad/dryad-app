class RemoveImportDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default :stash_engine_identifiers, :import_info, from: 0, to: nil
  end
end
