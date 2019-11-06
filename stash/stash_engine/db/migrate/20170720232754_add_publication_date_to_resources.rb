class AddPublicationDateToResources < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :publication_date, :datetime
  end
end
