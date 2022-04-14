class DropTermsAcceptedAtFromStashEngineUser < ActiveRecord::Migration[4.2]
  def change
    remove_column :stash_engine_users, :terms_accepted_at
  end
end
