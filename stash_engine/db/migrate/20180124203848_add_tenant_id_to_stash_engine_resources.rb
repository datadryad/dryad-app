class AddTenantIdToStashEngineResources < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :tenant_id, :string, limit: 100, null: false, index: true
  end
end
