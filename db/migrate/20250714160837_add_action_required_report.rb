class AddActionRequiredReport < ActiveRecord::Migration[8.0]
  def change
    create_table :action_required_reports do |t|
      t.text :report
      t.integer :resource_id
      t.integer :user_id

      t.timestamps
    end
  end
end
