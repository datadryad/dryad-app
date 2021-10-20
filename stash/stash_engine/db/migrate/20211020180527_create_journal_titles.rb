class CreateJournalTitles < ActiveRecord::Migration[5.2]
  def change
    create_table :stash_engine_journal_titles do |t|
      t.string :title
      t.integer :journal_id
      t.timestamps
    end    
  end
end
