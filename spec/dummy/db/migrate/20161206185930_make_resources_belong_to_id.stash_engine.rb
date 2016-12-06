# This migration comes from stash_engine (originally 20160516182448)
class MakeResourcesBelongToId < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :identifier_id, :integer
    remove_column :stash_engine_identifiers, :resource_id
  end
end
