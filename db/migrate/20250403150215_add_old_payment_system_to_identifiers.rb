class AddOldPaymentSystemToIdentifiers < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_identifiers, :old_payment_system, :boolean, default: false
  end
end
