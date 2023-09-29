class AddNameToXrefFunderToRors < ActiveRecord::Migration[6.1]
  def change
    add_column :stash_engine_xref_funder_to_rors, :org_name, :text
  end
end
