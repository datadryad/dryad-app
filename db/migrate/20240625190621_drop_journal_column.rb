class DropJournalColumn < ActiveRecord::Migration[7.0]
  def change
    remove_column :stash_engine_journals, :issn, :string
  end
end
