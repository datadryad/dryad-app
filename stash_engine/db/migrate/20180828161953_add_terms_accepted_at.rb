class AddTermsAcceptedAt < ActiveRecord::Migration
  def change
    add_column :stash_engine_users, :terms_accepted_at, :string, default: nil
  end
end
