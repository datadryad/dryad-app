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
      end
      dir.down do
        # making sure changes to the tenant ids are reverted if the migration is rolled back
        Rake::Task['tenants:rename'].invoke('reverse')
      end
    end
  end
end
