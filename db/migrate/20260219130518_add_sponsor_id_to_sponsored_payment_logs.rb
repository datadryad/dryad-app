class AddSponsorIdToSponsoredPaymentLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :sponsored_payment_logs, :sponsor_id, :string
    add_index :sponsored_payment_logs, :sponsor_id
  end
end
