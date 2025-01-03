class MultipleResourcePublication < ActiveRecord::Migration[7.0]
  def change
    add_column :stash_engine_resource_publications, :pub_type, :integer, default: 0
    remove_index :stash_engine_resource_publications, :resource_id
    add_index :stash_engine_resource_publications, [:resource_id, :pub_type], unique: true, name: 'index_resource_pub_type'
  end
end
