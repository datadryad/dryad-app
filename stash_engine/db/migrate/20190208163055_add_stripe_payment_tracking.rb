class AddStripePaymentTracking < ActiveRecord::Migration
  def change
    add_column :stash_engine_users, :customer_id, :text
    add_column :stash_engine_identifiers, :invoice_id, :text
  end
end
