class AddValidationTriesToStashEngineUsers < ActiveRecord::Migration
  def change
    add_column :stash_engine_users, :validation_tries, :integer, default: 0
  end
end
