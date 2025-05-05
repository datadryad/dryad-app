class AddCoversLdfToJournals < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_journals, :covers_ldf, :boolean, default: false
  end
end
