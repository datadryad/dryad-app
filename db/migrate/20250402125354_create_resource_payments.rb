class CreateResourcePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :resource_payments do |t|
      t.integer :resource_id
      t.string :payment_type
      t.integer :amount
      t.string :checkout_session_id
      t.integer :status

      t.timestamps
    end

    add_index :resource_payments, :resource_id
    add_index :resource_payments, :checkout_session_id
    add_index :resource_payments, :status
  end
end
