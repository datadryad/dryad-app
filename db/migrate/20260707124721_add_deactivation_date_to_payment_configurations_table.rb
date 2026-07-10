class AddDeactivationDateToPaymentConfigurationsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_configurations, :deactivated_at, :datetime, default: nil
  end
end
