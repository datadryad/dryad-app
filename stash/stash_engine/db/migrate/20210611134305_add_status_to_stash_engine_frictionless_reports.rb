class AddStatusToStashEngineFrictionlessReports < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_frictionless_reports, :status,
               "ENUM('valid','invalid', 'checking', 'errors')", limit: 15
  end
end
