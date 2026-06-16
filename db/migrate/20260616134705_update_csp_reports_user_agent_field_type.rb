class UpdateCspReportsUserAgentFieldType < ActiveRecord::Migration[8.0]
  def up
    change_column :csp_reports, :user_agent, :text
  end

  def down
    change_column :csp_reports, :user_agent, :string
  end
end
