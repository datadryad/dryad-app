class DropTermsAcceptedAtFromStashEngineUser < ActiveRecord::Migration
  def change
    remove_column :stash_engine_users, :terms_accepted_at
  end
end
