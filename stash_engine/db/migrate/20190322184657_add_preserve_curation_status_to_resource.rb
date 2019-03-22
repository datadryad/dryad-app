class AddPreserveCurationStatusToResource < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :preserve_curation_status, :boolean, default: false
  end
end
