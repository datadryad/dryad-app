class AddPaymentRecordTable < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_records do |t|
      t.string :payment_id
      t.string :payment_type
      t.string :payment_plan
      t.bigint :identifier_id
      t.bigint :resource_id
      t.string :fee_type, default: 'dpc'
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :payment_records, [:payment_type, :payment_id]
    add_index :payment_records, [:identifier_id, :fee_type]
    add_index :payment_records, [:resource_id, :fee_type]
  end
end
