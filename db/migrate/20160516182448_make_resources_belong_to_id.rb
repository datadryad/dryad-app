class MakeResourcesBelongToId < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :identifier_id, :integer
    remove_column :stash_engine_identifiers, :resource_id
  end
end
