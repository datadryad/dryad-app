class AddEditCodeToIdentifier < ActiveRecord::Migration[5.2]
  def up
    add_column :stash_engine_identifiers, :edit_code, :string
  end

  def down
    remove_column :stash_engine_identifiers, :edit_code
  end
end
