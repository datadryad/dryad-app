class AddPreserveCurationStatusToResource < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :preserve_curation_status, :boolean, default: false
  end
end
