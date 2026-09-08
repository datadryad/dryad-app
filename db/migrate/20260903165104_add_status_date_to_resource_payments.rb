class AddStatusDateToResourcePayments < ActiveRecord::Migration[8.0]
  def change
    add_column :resource_payments, :status_time, :datetime
  end
end
