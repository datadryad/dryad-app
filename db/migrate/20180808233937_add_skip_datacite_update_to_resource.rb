class AddSkipDataciteUpdateToResource < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :skip_datacite_update, :boolean, default: false
  end
end
