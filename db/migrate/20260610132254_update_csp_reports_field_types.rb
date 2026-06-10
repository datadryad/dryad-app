class UpdateCspReportsFieldTypes < ActiveRecord::Migration[8.0]
  def up
    change_column :csp_reports, :blocked_uri, :text
    change_column :csp_reports, :url, :text
  end

  def down
    change_column :csp_reports, :blocked_uri, :string
    change_column :csp_reports, :url, :string
  end
end
