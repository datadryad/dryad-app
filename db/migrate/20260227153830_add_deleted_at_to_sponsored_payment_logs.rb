class AddDeletedAtToSponsoredPaymentLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :sponsored_payment_logs, :deleted_at, :datetime
    add_index :sponsored_payment_logs, :deleted_at
  end
end
