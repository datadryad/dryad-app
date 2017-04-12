# This migration comes from stash_engine (originally 20160208223347)
class AddColumnToResources < ActiveRecord::Migration
  def up
    add_column :stash_engine_resources, :geolocation, :boolean, :default => false
  end

  def down
    remove_column :stash_engine_resources, :geolocation
  end
end
