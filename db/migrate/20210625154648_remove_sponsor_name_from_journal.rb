class RemoveSponsorNameFromJournal < ActiveRecord::Migration[5.2]
  def change
    remove_column :stash_engine_journals, :sponsor_name, :string  
  end
end
