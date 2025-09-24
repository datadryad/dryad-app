class AddEmailValidation < ActiveRecord::Migration[8.0]
  def change
    remove_column :stash_engine_users, :validation_tries, :integer, default: 0
    add_column :stash_engine_users, :validated, :boolean, default: false
  end
end
