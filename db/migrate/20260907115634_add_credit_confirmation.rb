class AddCreditConfirmation < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_authors, :credit_confirmed, :boolean, default: false
  end
end
