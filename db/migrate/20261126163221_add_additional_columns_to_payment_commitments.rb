class AddAdditionalColumnsToPaymentCommitments < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_commitments, :prepayment_carryover, :float, precision: 10, scale: 2 , after: :asf_prepaid
  end
end
