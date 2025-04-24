class AddPaidSessionIdAndInvoiceIdToResourcePayments < ActiveRecord::Migration[8.0]
  def change
    add_column :resource_payments, :invoice_id, :string
    add_column :resource_payments, :paid_at, :datetime
    add_column :resource_payments, :payment_checkout_session_id, :string
    add_column :resource_payments, :payment_status, :string
    add_column :resource_payments, :payment_intent, :string
    add_column :resource_payments, :payment_email, :string

    add_index :resource_payments, :paid_at
  end
end
