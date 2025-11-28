class AddYearlyFeeLimitToPaymentConfigurations < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_configurations, :yearly_ldf_fee_limit, :integer, after: :ldf_limit
  end
end
