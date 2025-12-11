class RemoveOldPaymentFieldsFromFunders < ActiveRecord::Migration[8.0]
  def change
    remove_column :stash_engine_funders, :old_payment_plan, :integer
    remove_column :stash_engine_funders, :old_covers_dpc, :boolean, default: false
    remove_column :stash_engine_funders, :old_covers_ldf, :boolean, default: false
  end
end
