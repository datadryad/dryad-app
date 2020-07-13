class AddPublicationDateToResources < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :publication_date, :datetime
  end
end
