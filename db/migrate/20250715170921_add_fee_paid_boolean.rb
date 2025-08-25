class AddFeePaidBoolean < ActiveRecord::Migration[8.0]
  def change
    add_column :resource_payments, :ppr_fee_paid, :boolean, default: false, after: :has_discount
  end
end
