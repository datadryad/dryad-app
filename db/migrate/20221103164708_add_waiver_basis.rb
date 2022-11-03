class AddWaiverBasis < ActiveRecord::Migration[5.2]
  def up
    add_column :stash_engine_identifiers, :waiver_basis, :string, after: :payment_id
    StashEngine::Identifier.all.each do |i|
      if i.payment_type && i.payment_type == 'waiver'
        # copy existing waiver countries to new column
        i.update_column(:waiver_basis, i.payment_id)
      end
    end
  end

  def down
    remove_column :stash_engine_identifiers, :waiver_basis
  end
end
