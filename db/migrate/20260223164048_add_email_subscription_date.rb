class AddEmailSubscriptionDate < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_saved_searches, :emailed_at, :datetime, after: :updated_at
  end
end
