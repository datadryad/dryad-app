class ChangeFrictionlessReportReportToLongText < ActiveRecord::Migration[6.1]
  def change
    change_column :stash_engine_frictionless_reports, :report, :text, :limit => 4294967295
  end
end
