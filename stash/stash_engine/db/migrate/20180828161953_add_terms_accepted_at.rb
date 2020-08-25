class AddTermsAcceptedAt < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_users, :terms_accepted_at, :string, default: nil
  end
end
