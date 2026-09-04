class AddSubmitterContact < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_configurations, :submitter_contact, :text
  end
end
