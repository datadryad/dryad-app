class AddReceiptTable < ActiveRecord::Migration[8.0]
  def change
    create_table :fee_records do |t|
      t.bigint :resource_id
      t.json :fees
      t.integer :status, default: 0

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
