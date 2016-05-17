class MakeResourcesBelongToId < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :identifier_id, :integer
    remove_column :stash_engine_identifiers, :resource_id
  end
end
