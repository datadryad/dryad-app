class DropStashEngineXrefFunderToRorsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :stash_engine_xref_funder_to_rors
  end

  def down
    create_table :stash_engine_xref_funder_to_rors do |t|
      t.string :xref_id, index: true
      t.string :ror_id, index: true
      t.text :org_name
    end
  end
end
