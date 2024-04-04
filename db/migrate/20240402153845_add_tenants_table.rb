class AddTenantsTable < ActiveRecord::Migration[6.1]
  def change
    create_table :stash_engine_tenants, id: :string do |t|
      t.string :short_name
      t.string :long_name
      t.json :authentication
      t.json :campus_contacts
      t.integer :payment_plan
      t.boolean :enabled, default: true
      t.boolean :partner_display, default: true
      t.boolean :covers_dpc, default: true
      t.string :sponsor_id
      t.timestamps
    end
    add_index :stash_engine_tenants, :id
    create_table :stash_engine_tenant_ror_orgs do |t|
      t.string :tenant_id
      t.string :ror_id
      t.timestamps
    end
    add_index :stash_engine_tenant_ror_orgs, [:tenant_id, :ror_id]
    add_foreign_key :stash_engine_tenant_ror_orgs, :stash_engine_tenants, column: :tenant_id
    reversible do |dir|
      dir.up do
        Rake::Task['tenants:seed'].invoke
        StashEngine::User.where(tenant_id: 'victoria').in_batches.update_all(tenant_id: 'vu')
        StashEngine::Resource.where(tenant_id: 'victoria').in_batches.update_all(tenant_id: 'vu')
        StashEngine::Identifier.where(payment_id: 'victoria').in_batches.update_all(payment_id: 'vu')
        StashEngine::User.where(tenant_id: 'msu').in_batches.update_all(tenant_id: 'montana')
        StashEngine::Resource.where(tenant_id: 'msu').in_batches.update_all(tenant_id: 'montana')
        StashEngine::Identifier.where(payment_id: 'msu').in_batches.update_all(payment_id: 'montana')
        StashEngine::User.where(tenant_id: 'msu2').in_batches.update_all(tenant_id: 'msu')
        StashEngine::Resource.where(tenant_id: 'msu2').in_batches.update_all(tenant_id: 'msu')
        StashEngine::Identifier.where(payment_id: 'msu2').in_batches.update_all(payment_id: 'msu')
        StashEngine::User.where(tenant_id: 'ohiostate').in_batches.update_all(tenant_id: 'osu')
        StashEngine::Resource.where(tenant_id: 'ohiostate').in_batches.update_all(tenant_id: 'osu')
        StashEngine::Identifier.where(payment_id: 'ohiostate').in_batches.update_all(payment_id: 'osu')
        StashEngine::User.where(tenant_id: 'sydneynsw').in_batches.update_all(tenant_id: 'unsw')
        StashEngine::Resource.where(tenant_id: 'sydneynsw').in_batches.update_all(tenant_id: 'unsw')
        StashEngine::Identifier.where(payment_id: 'sydneynsw').in_batches.update_all(payment_id: 'unsw')
      end
      dir.down do
        StashEngine::User.where(tenant_id: 'vu').in_batches.update_all(tenant_id: 'victoria')
        StashEngine::Resource.where(tenant_id: 'vu').in_batches.update_all(tenant_id: 'victoria')
        StashEngine::Identifier.where(payment_id: 'vu').in_batches.update_all(payment_id: 'victoria')
        StashEngine::User.where(tenant_id: 'unsw').in_batches.update_all(tenant_id: 'sydneynsw')
        StashEngine::Resource.where(tenant_id: 'unsw').in_batches.update_all(tenant_id: 'sydneynsw')
        StashEngine::Identifier.where(payment_id: 'unsw').in_batches.update_all(payment_id: 'sydneynsw')
        StashEngine::User.where(tenant_id: 'osu').in_batches.update_all(tenant_id: 'ohiostate')
        StashEngine::Resource.where(tenant_id: 'osu').in_batches.update_all(tenant_id: 'ohiostate')
        StashEngine::Identifier.where(payment_id: 'osu').in_batches.update_all(payment_id: 'ohiostate')
        StashEngine::User.where(tenant_id: 'msu').in_batches.update_all(tenant_id: 'msu2')
        StashEngine::Resource.where(tenant_id: 'msu').in_batches.update_all(tenant_id: 'msu2')
        StashEngine::Identifier.where(payment_id: 'msu').in_batches.update_all(payment_id: 'msu2')
        StashEngine::User.where(tenant_id: 'montana').in_batches.update_all(tenant_id: 'msu')
        StashEngine::Resource.where(tenant_id: 'montana').in_batches.update_all(tenant_id: 'msu')
        StashEngine::Identifier.where(payment_id: 'montana').in_batches.update_all(payment_id: 'msu')
      end
    end
  end
end
