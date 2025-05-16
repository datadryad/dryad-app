class AddHasDiscountToResourcePayments < ActiveRecord::Migration[8.0]
  def change
    add_column :resource_payments, :has_discount, :boolean, default: false
  end
end
