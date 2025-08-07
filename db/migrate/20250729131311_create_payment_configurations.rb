class CreatePaymentConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_configurations do |t|
      t.string :partner_id
      t.string :partner_type
      t.integer :payment_plan
      t.boolean :covers_dpc
      t.boolean :covers_ldf
      t.integer :ldf_limit

      t.timestamps
    end
  end
end
