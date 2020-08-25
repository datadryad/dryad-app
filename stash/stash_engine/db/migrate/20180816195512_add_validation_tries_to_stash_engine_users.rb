class AddValidationTriesToStashEngineUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_users, :validation_tries, :integer, default: 0
  end
end
