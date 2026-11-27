class CreateSponsorInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :sponsor_invoices do |t|
      t.string :sponsor_id
      t.string :sponsor_type
      t.integer :year
      t.float :amount
      t.string :s3_key

      t.timestamps
    end

    add_index :sponsor_invoices, %i[sponsor_id sponsor_type]
  end
end
