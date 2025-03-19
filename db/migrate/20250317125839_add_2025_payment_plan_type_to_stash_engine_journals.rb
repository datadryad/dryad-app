class Add2025PaymentPlanTypeToStashEngineJournals < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL.freeze
      ALTER TABLE stash_engine_journals MODIFY COLUMN `payment_plan_type` enum('PREPAID','DEFERRED','SUBSCRIPTION','TIERED','2025');
    SQL
  end

  def down
    execute <<-SQL.freeze
      ALTER TABLE stash_engine_journals MODIFY COLUMN `payment_plan_type` enum('PREPAID','DEFERRED','SUBSCRIPTION','TIERED');
    SQL
  end
end
