class AddPayWithInvoiceToResourcePayments < ActiveRecord::Migration[8.0]
  def change
    add_column :resource_payments, :pay_with_invoice, :boolean, default: false, after: :updated_at
    add_column :resource_payments, :invoice_details, :json, after: :pay_with_invoice
  end
end
