class AddTenantIdToStashEngineResources < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :tenant_id, :string, limit: 100, default: nil, index: true
  end
end
