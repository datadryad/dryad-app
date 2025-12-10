class RemoveOldPaymentFieldsFromJournals < ActiveRecord::Migration[8.0]
  def change
    remove_column :stash_engine_journals, :old_payment_plan_type, "ENUM('PREPAID', 'DEFERRED', 'SUBSCRIPTION')"
    remove_column :stash_engine_journals, :old_covers_ldf, :boolean, default: false
  end
end
