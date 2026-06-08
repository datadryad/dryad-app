class AddLdfLimitNotificationToPaymentConfigurationsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_configurations, :ldf_limit_notification, :boolean, default: false, after: :yearly_ldf_limit
  end
end
