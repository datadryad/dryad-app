class CreatePaymentCommitments < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_commitments do |t|
      t.string :sponsor_id
      t.string :sponsor_type
      t.date :start_date
      t.integer :commitment_years
      t.integer :year_index
      t.integer :year
      t.string :payment_plan
      t.float :dpc_commitment_price
      t.integer :dpc_commitment
      t.integer :dpc_carryover
      t.boolean :covers_ldf
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

    add_index :payment_commitments, %i[sponsor_id sponsor_type]
  end
end
