class AddStatusToStashEngineFrictionlessReports < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_frictionless_reports, :status,
               "ENUM('issues','noissues', 'checking', 'error')"
  end
end
