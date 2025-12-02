class CreateSponsoredPaymentLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :sponsored_payment_logs do |t|
      t.integer :resource_id
      t.string :payer_id
      t.string :payer_type
      t.integer :dpc
      t.integer :ldf
      t.integer :paid_storage

      t.timestamps
    end

    add_index :sponsored_payment_logs, [:payer_id, :payer_type]
  end
end
