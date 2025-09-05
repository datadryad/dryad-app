class RenameOldPaymentConfigurationFields < ActiveRecord::Migration[8.0]
  def change
    rename_column :stash_engine_journals, :payment_plan_type, :old_payment_plan_type
    rename_column :stash_engine_journals, :covers_ldf, :old_covers_ldf

    rename_column :stash_engine_tenants, :payment_plan, :old_payment_plan
    rename_column :stash_engine_tenants, :covers_dpc, :old_covers_dpc
    rename_column :stash_engine_tenants, :covers_ldf, :old_covers_ldf

    rename_column :stash_engine_funders, :payment_plan, :old_payment_plan
    rename_column :stash_engine_funders, :covers_dpc, :old_covers_dpc
    rename_column :stash_engine_funders, :covers_ldf, :old_covers_ldf
  end
end
