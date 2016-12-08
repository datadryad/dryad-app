require 'spec_helper'

module StashEngine
  describe Tenant do
    describe 'initialize' do
      it 'creates a tenant' do
        tenant_hash = YAML.load_file('spec/data/tenant-example.yml')['test']
        tenant = Tenant.new(tenant_hash)
        expect(tenant.tenant_id).to eq('exemplia')
        expect(tenant.abbreviation).to eq('EX')
        expect(tenant.short_name).to eq('Exemplia')
        expect(tenant.long_name).to eq('University of Exemplia')
        expect(tenant.full_domain).to eq('stash-dev.example.edu')
        expect(tenant.domain_regex).to eq('example.edu$')
        expect(tenant.contact_email).to eq(%w(contact1@example.edu contact2@example.edu))
        expect(tenant.default_license).to eq('cc_by')
        expect(tenant.stash_logo_after_tenant).to eq(true)
        repo = tenant.repository
        expect(repo.type).to eq('exemplum')
        expect(repo.domain).to eq('repo-dev.example.edu')
        expect(repo.endpoint).to eq('http://repo-dev.example.edu:39001/sword/collection/stash')
        expect(repo.username).to eq('stash_submitter')
        expect(repo.password).to eq('correct​horse​battery​staple')
        ident = tenant.identifier_service
        expect(ident.shoulder).to eq('doi:10.5072/5555')
        expect(ident.account).to eq('stash')
        expect(ident.password).to eq('stash')
        expect(ident.id_scheme).to eq('doi')
        expect(ident.owner).to be_nil
        auth = tenant.authentication
        expect(auth.strategy).to eq('shibboleth')
        expect(auth.entity_id).to eq('urn:mace:incommon:example.edu')
        expect(auth.entity_domain).to eq('.example.edu')
      end
    end
  end
end
