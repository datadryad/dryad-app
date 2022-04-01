class ChangeColumnFromStashEngineFrictionlessReports < ActiveRecord::Migration[5.2]
  def change
    change_table :stash_engine_frictionless_reports do |t|
      t.change :report, :text, :limit => 16.megabytes - 1
    end
  end
end
