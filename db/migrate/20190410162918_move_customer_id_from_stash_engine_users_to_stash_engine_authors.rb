class MoveCustomerIdFromStashEngineUsersToStashEngineAuthors < ActiveRecord::Migration[4.2]
  def change
    remove_column :stash_engine_users, :customer_id
    add_column :stash_engine_authors, :stripe_customer_id, :text
  end
end
