class CreateCspReports < ActiveRecord::Migration[8.0]
  def change
    create_table :csp_reports do |t|
      t.string :ip
      t.string :user_agent
      t.string :blocked_uri
      t.string :url
      t.string :directive
      t.string :status_code
      t.json :report

      t.timestamps
    end
  end
end
