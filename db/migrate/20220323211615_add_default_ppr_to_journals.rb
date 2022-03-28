class AddDefaultPprToJournals < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_journals, :default_to_ppr, :boolean, after: :allow_blackout, default: 0
  end
end
