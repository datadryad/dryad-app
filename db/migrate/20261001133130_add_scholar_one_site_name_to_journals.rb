class AddScholarOneSiteNameToJournals < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_journals, :scholar_one_site_name, :string
  end
end
