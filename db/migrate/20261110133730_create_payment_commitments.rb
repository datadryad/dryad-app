class CreatePaymentCommitments < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_commitments do |t|
      t.integer :payment_configuration_id
      t.date :start_date
      t.integer :commitment_years
      t.integer :year_index
      t.integer :year
      t.string :payment_plan
      t.float :dpc_commitment_price
      t.integer :dpc_commitment
      t.integer :dpc_carryover
      t.float :ldf_commitment
      t.float :ldf_carryover
      t.integer :ldf_size_limit
      t.float :asf
      t.float :period_discount
      t.float :consortium_discount
      t.float :asf_due
      t.float :asf_prepaid
      t.datetime :deleted_at
      t.json :update_notes
      t.string :batch

      t.timestamps
    end
  end
end
