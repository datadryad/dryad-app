class AddJournalIntegrationDate < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_journals, :integrated_at, :datetime, after: :updated_at
  end
end
