class AddDpcTierToPaymentCommitments < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_commitments, :dpc_tier, :integer
  end
end
