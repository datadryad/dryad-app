class AddCodeToJournals < ActiveRecord::Migration[5.2]
  def change
    add_column :stash_engine_journals, :journal_code, :string
  end
end
