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
        StashEngine::User.where(tenant_id: 'csueb').in_batches.update_all(tenant_id: 'csueastbay')
        StashEngine::Resource.where(tenant_id: 'csueb').in_batches.update_all(tenant_id: 'csueastbay')
        StashEngine::Identifier.where(payment_id: 'csueb').in_batches.update_all(payment_id: 'csueastbay')        
        StashEngine::User.where(tenant_id: 'lbnl').in_batches.update_all(tenant_id: 'lbl')
        StashEngine::Resource.where(tenant_id: 'lbnl').in_batches.update_all(tenant_id: 'lbl')
        StashEngine::Identifier.where(payment_id: 'lbnl').in_batches.update_all(payment_id: 'lbl')
        StashEngine::User.where(tenant_id: 'sheffield').in_batches.update_all(tenant_id: 'shef')
        StashEngine::Resource.where(tenant_id: 'sheffield').in_batches.update_all(tenant_id: 'shef')
        StashEngine::Identifier.where(payment_id: 'sheffield').in_batches.update_all(payment_id: 'shef')

        # Clare consortium
        StashEngine::User.where(tenant_id: 'clare-cs').in_batches.update_all(tenant_id: 'claremont')
        StashEngine::Resource.where(tenant_id: 'clare-cs').in_batches.update_all(tenant_id: 'claremont')
        StashEngine::Identifier.where(payment_id: 'clare-cs').in_batches.update_all(payment_id: 'claremont')
        StashEngine::User.where(tenant_id: 'clare-cgu').in_batches.update_all(tenant_id: 'cgu')
        StashEngine::Resource.where(tenant_id: 'clare-cgu').in_batches.update_all(tenant_id: 'cgu')
        StashEngine::Identifier.where(payment_id: 'clare-cgu').in_batches.update_all(payment_id: 'cgu')
        StashEngine::User.where(tenant_id: 'clare-cmc').in_batches.update_all(tenant_id: 'cmc')
        StashEngine::Resource.where(tenant_id: 'clare-cmc').in_batches.update_all(tenant_id: 'cmc')
        StashEngine::Identifier.where(payment_id: 'clare-cmc').in_batches.update_all(payment_id: 'cmc')
        StashEngine::User.where(tenant_id: 'clare-hmc').in_batches.update_all(tenant_id: 'hmc')
        StashEngine::Resource.where(tenant_id: 'clare-hmc').in_batches.update_all(tenant_id: 'hmc')
        StashEngine::Identifier.where(payment_id: 'clare-hmc').in_batches.update_all(payment_id: 'hmc')
        StashEngine::User.where(tenant_id: 'clare-kgi').in_batches.update_all(tenant_id: 'kgi')
        StashEngine::Resource.where(tenant_id: 'clare-kgi').in_batches.update_all(tenant_id: 'kgi')
        StashEngine::Identifier.where(payment_id: 'clare-kgi').in_batches.update_all(payment_id: 'kgi')
        StashEngine::User.where(tenant_id: 'clare-pitzer').in_batches.update_all(tenant_id: 'pitzer')
        StashEngine::Resource.where(tenant_id: 'clare-pitzer').in_batches.update_all(tenant_id: 'pitzer')
        StashEngine::Identifier.where(payment_id: 'clare-pitzer').in_batches.update_all(payment_id: 'pitzer')
        StashEngine::User.where(tenant_id: 'clare-pomona').in_batches.update_all(tenant_id: 'pomona')
        StashEngine::Resource.where(tenant_id: 'clare-pomona').in_batches.update_all(tenant_id: 'pomona')
        StashEngine::Identifier.where(payment_id: 'clare-pomona').in_batches.update_all(payment_id: 'pomona')
        StashEngine::User.where(tenant_id: 'clare-scripps').in_batches.update_all(tenant_id: 'scrippscollege')
        StashEngine::Resource.where(tenant_id: 'clare-scripps').in_batches.update_all(tenant_id: 'scrippscollege')
        StashEngine::Identifier.where(payment_id: 'clare-scripps').in_batches.update_all(payment_id: 'scrippscollege')

        #SUNY consortium
        StashEngine::User.where(tenant_id: 'suny-buffalo').in_batches.update_all(tenant_id: 'buffalo')
        StashEngine::Resource.where(tenant_id: 'suny-buffalo').in_batches.update_all(tenant_id: 'buffalo')
        StashEngine::Identifier.where(payment_id: 'suny-buffalo').in_batches.update_all(payment_id: 'buffalo')
        StashEngine::User.where(tenant_id: 'suny-buffalostate').in_batches.update_all(tenant_id: 'buffalostate')
        StashEngine::Resource.where(tenant_id: 'suny-buffalostate').in_batches.update_all(tenant_id: 'buffalostate')
        StashEngine::Identifier.where(payment_id: 'suny-buffalostate').in_batches.update_all(payment_id: 'buffalostate')
        StashEngine::User.where(tenant_id: 'suny-downstate').in_batches.update_all(tenant_id: 'downstate')
        StashEngine::Resource.where(tenant_id: 'suny-downstate').in_batches.update_all(tenant_id: 'downstate')
        StashEngine::Identifier.where(payment_id: 'suny-downstate').in_batches.update_all(payment_id: 'downstate')
        StashEngine::User.where(tenant_id: 'suny-fredonia').in_batches.update_all(tenant_id: 'fredonia')
        StashEngine::Resource.where(tenant_id: 'suny-fredonia').in_batches.update_all(tenant_id: 'fredonia')
        StashEngine::Identifier.where(payment_id: 'suny-fredonia').in_batches.update_all(payment_id: 'fredonia')
        StashEngine::User.where(tenant_id: 'suny-geneseo').in_batches.update_all(tenant_id: 'geneseo')
        StashEngine::Resource.where(tenant_id: 'suny-geneseo').in_batches.update_all(tenant_id: 'geneseo')
        StashEngine::Identifier.where(payment_id: 'suny-geneseo').in_batches.update_all(payment_id: 'geneseo')
        StashEngine::User.where(tenant_id: 'suny-stonybrook').in_batches.update_all(tenant_id: 'stonybrook')
        StashEngine::Resource.where(tenant_id: 'suny-stonybrook').in_batches.update_all(tenant_id: 'stonybrook')
        StashEngine::Identifier.where(payment_id: 'suny-stonybrook').in_batches.update_all(payment_id: 'stonybrook')

        #UC system
        StashEngine::User.where(tenant_id: 'ucb').in_batches.update_all(tenant_id: 'berkeley')
        StashEngine::Resource.where(tenant_id: 'ucb').in_batches.update_all(tenant_id: 'berkeley')
        StashEngine::Identifier.where(payment_id: 'ucb').in_batches.update_all(payment_id: 'berkeley')
        StashEngine::User.where(tenant_id: 'ucd').in_batches.update_all(tenant_id: 'ucdavis')
        StashEngine::Resource.where(tenant_id: 'ucd').in_batches.update_all(tenant_id: 'ucdavis')
        StashEngine::Identifier.where(payment_id: 'ucd').in_batches.update_all(payment_id: 'ucdavis')
        StashEngine::User.where(tenant_id: 'ucm').in_batches.update_all(tenant_id: 'ucmerced')
        StashEngine::Resource.where(tenant_id: 'ucm').in_batches.update_all(tenant_id: 'ucmerced')
        StashEngine::Identifier.where(payment_id: 'ucm').in_batches.update_all(payment_id: 'ucmerced')
      end
      dir.down do
        StashEngine::User.where(tenant_id: 'shef').in_batches.update_all(tenant_id: 'sheffield')
        StashEngine::Resource.where(tenant_id: 'shef').in_batches.update_all(tenant_id: 'sheffield')
        StashEngine::Identifier.where(payment_id: 'shef').in_batches.update_all(payment_id: 'sheffield')
        StashEngine::User.where(tenant_id: 'lbl').in_batches.update_all(tenant_id: 'lbnl')
        StashEngine::Resource.where(tenant_id: 'lbl').in_batches.update_all(tenant_id: 'lbnl')
        StashEngine::Identifier.where(payment_id: 'lbl').in_batches.update_all(payment_id: 'lbnl')
        StashEngine::User.where(tenant_id: 'csueastbay').in_batches.update_all(tenant_id: 'csueb')
        StashEngine::Resource.where(tenant_id: 'csueastbay').in_batches.update_all(tenant_id: 'csueb')
        StashEngine::Identifier.where(payment_id: 'csueastbay').in_batches.update_all(payment_id: 'csueb')
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

        #UC system
        StashEngine::User.where(tenant_id: 'berkeley').in_batches.update_all(tenant_id: 'ucb')
        StashEngine::Resource.where(tenant_id: 'berkeley').in_batches.update_all(tenant_id: 'ucb')
        StashEngine::Identifier.where(payment_id: 'berkeley').in_batches.update_all(payment_id: 'ucb')
        StashEngine::User.where(tenant_id: 'ucdavis').in_batches.update_all(tenant_id: 'ucd')
        StashEngine::Resource.where(tenant_id: 'ucdavis').in_batches.update_all(tenant_id: 'ucd')
        StashEngine::Identifier.where(payment_id: 'ucdavis').in_batches.update_all(payment_id: 'ucd')
        StashEngine::User.where(tenant_id: 'ucmerced').in_batches.update_all(tenant_id: 'ucm')
        StashEngine::Resource.where(tenant_id: 'ucmerced').in_batches.update_all(tenant_id: 'ucm')
        StashEngine::Identifier.where(payment_id: 'ucmerced').in_batches.update_all(payment_id: 'ucm')

        #SUNY consortium
        StashEngine::User.where(tenant_id: 'buffalo').in_batches.update_all(tenant_id: 'suny-buffalo')
        StashEngine::Resource.where(tenant_id: 'buffalo').in_batches.update_all(tenant_id: 'suny-buffalo')
        StashEngine::Identifier.where(payment_id: 'buffalo').in_batches.update_all(payment_id: 'suny-buffalo')
        StashEngine::User.where(tenant_id: 'buffalostate').in_batches.update_all(tenant_id: 'suny-buffalostate')
        StashEngine::Resource.where(tenant_id: 'buffalostate').in_batches.update_all(tenant_id: 'suny-buffalostate')
        StashEngine::Identifier.where(payment_id: 'buffalostate').in_batches.update_all(payment_id: 'suny-buffalostate')
        StashEngine::User.where(tenant_id: 'downstate').in_batches.update_all(tenant_id: 'suny-downstate')
        StashEngine::Resource.where(tenant_id: 'downstate').in_batches.update_all(tenant_id: 'suny-downstate')
        StashEngine::Identifier.where(payment_id: 'downstate').in_batches.update_all(payment_id: 'suny-downstate')
        StashEngine::User.where(tenant_id: 'fredonia').in_batches.update_all(tenant_id: 'suny-fredonia')
        StashEngine::Resource.where(tenant_id: 'fredonia').in_batches.update_all(tenant_id: 'suny-fredonia')
        StashEngine::Identifier.where(payment_id: 'fredonia').in_batches.update_all(payment_id: 'suny-fredonia')
        StashEngine::User.where(tenant_id: 'geneseo').in_batches.update_all(tenant_id: 'suny-geneseo')
        StashEngine::Resource.where(tenant_id: 'geneseo').in_batches.update_all(tenant_id: 'suny-geneseo')
        StashEngine::Identifier.where(payment_id: 'geneseo').in_batches.update_all(payment_id: 'suny-geneseo')
        StashEngine::User.where(tenant_id: 'stonybrook').in_batches.update_all(tenant_id: 'suny-stonybrook')
        StashEngine::Resource.where(tenant_id: 'stonybrook').in_batches.update_all(tenant_id: 'suny-stonybrook')
        StashEngine::Identifier.where(payment_id: 'stonybrook').in_batches.update_all(payment_id: 'suny-stonybrook')

        # Clare consortium
        StashEngine::User.where(tenant_id: 'claremont').in_batches.update_all(tenant_id: 'clare-cs')
        StashEngine::Resource.where(tenant_id: 'claremont').in_batches.update_all(tenant_id: 'clare-cs')
        StashEngine::Identifier.where(payment_id: 'claremont').in_batches.update_all(payment_id: 'clare-cs')
        StashEngine::User.where(tenant_id: 'cgu').in_batches.update_all(tenant_id: 'clare-cgu')
        StashEngine::Resource.where(tenant_id: 'cgu').in_batches.update_all(tenant_id: 'clare-cgu')
        StashEngine::Identifier.where(payment_id: 'cgu').in_batches.update_all(payment_id: 'clare-cgu')
        StashEngine::User.where(tenant_id: 'cmc').in_batches.update_all(tenant_id: 'clare-cmc')
        StashEngine::Resource.where(tenant_id: 'cmc').in_batches.update_all(tenant_id: 'clare-cmc')
        StashEngine::Identifier.where(payment_id: 'cmc').in_batches.update_all(payment_id: 'clare-cmc')
        StashEngine::User.where(tenant_id: 'hmc').in_batches.update_all(tenant_id: 'clare-hmc')
        StashEngine::Resource.where(tenant_id: 'hmc').in_batches.update_all(tenant_id: 'clare-hmc')
        StashEngine::Identifier.where(payment_id: 'hmc').in_batches.update_all(payment_id: 'clare-hmc')
        StashEngine::User.where(tenant_id: 'kgi').in_batches.update_all(tenant_id: 'clare-kgi')
        StashEngine::Resource.where(tenant_id: 'kgi').in_batches.update_all(tenant_id: 'clare-kgi')
        StashEngine::Identifier.where(payment_id: 'kgi').in_batches.update_all(payment_id: 'clare-kgi')
        StashEngine::User.where(tenant_id: 'pitzer').in_batches.update_all(tenant_id: 'clare-pitzer')
        StashEngine::Resource.where(tenant_id: 'pitzer').in_batches.update_all(tenant_id: 'clare-pitzer')
        StashEngine::Identifier.where(payment_id: 'pitzer').in_batches.update_all(payment_id: 'clare-pitzer')
        StashEngine::User.where(tenant_id: 'pomona').in_batches.update_all(tenant_id: 'clare-pomona')
        StashEngine::Resource.where(tenant_id: 'pomona').in_batches.update_all(tenant_id: 'clare-pomona')
        StashEngine::Identifier.where(payment_id: 'pomona').in_batches.update_all(payment_id: 'clare-pomona')
        StashEngine::User.where(tenant_id: 'scrippscollege').in_batches.update_all(tenant_id: 'clare-scripps')
        StashEngine::Resource.where(tenant_id: 'scrippscollege').in_batches.update_all(tenant_id: 'clare-scripps')
        StashEngine::Identifier.where(payment_id: 'scrippscollege').in_batches.update_all(payment_id: 'clare-scripps')
      end
    end
  end
end
