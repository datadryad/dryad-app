class AddTieredPaymentPlan < ActiveRecord::Migration[6.1]
  def change
    execute <<-SQL.freeze
      ALTER TABLE stash_engine_journals MODIFY COLUMN `payment_plan_type` enum('PREPAID','DEFERRED','SUBSCRIPTION','TIERED');
    SQL
  end
end
