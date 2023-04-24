class CreateXrefFunderToRors < ActiveRecord::Migration[6.1]
  def change
    create_table :stash_engine_xref_funder_to_rors do |t|
      t.string :xref_id, index: true
      t.string :ror_id, index: true
    end
  end
end
