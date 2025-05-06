class AddDeletedAtToResourcePayments < ActiveRecord::Migration[8.0]
  def change
    add_column :resource_payments, :deleted_at, :datetime
    add_index :resource_payments, :deleted_at
  end
end
