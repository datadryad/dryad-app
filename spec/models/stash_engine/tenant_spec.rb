require 'tmpdir'
require 'fileutils'

module StashEngine
  describe Tenant do
    def expect_exemplia(tenant)
      expect(tenant.tenant_id).to eq('exemplia')
      expect(tenant.abbreviation).to eq('EX')
      expect(tenant.short_name).to eq('Exemplia')
      expect(tenant.long_name).to eq('University of Exemplia')
      expect(tenant.default_license).to eq('cc_by')
      expect(tenant.stash_logo_after_tenant).to eq(true)
      auth = tenant.authentication
      expect(auth.strategy).to eq('shibboleth')
      expect(auth.entity_id).to eq('urn:mace:incommon:example.edu')
      expect(auth.entity_domain).to eq('.example.edu')
    end

    describe :initialize do
      it 'creates a tenant' do
        tenant_hash = YAML.load_file('spec/data/tenant-example.yml')['test']
        tenant = Tenant.new(tenant_hash)
        expect_exemplia(tenant)
      end
    end

    describe :find do
      it 'finds a test tenant' do
        tenant = Tenant.find('dataone')
        expect(tenant.tenant_id).to eq('dataone')
        expect(tenant.long_name).to eq('DataONE')
        expect(tenant.authentication.strategy).to eq('author_match')
        # not going to check all since we've already tried that in initialize and not needed
      end

      it 'finds the tenant by long_name' do
        tenant = Tenant.find_by_long_name('Dryad Data Platform')
        expect(tenant.tenant_id).to eq('dryad')
        expect(tenant.long_name).to eq('Dryad Data Platform')
        expect(tenant.authentication.strategy).to eq('none')
        # not going to check all since we've already tried that in initialize and not needed
      end
    end

    describe :omniauth_login_path do
      it 'delegates to the auth strategy' do
        tenant = Tenant.find('ucop')
        login_path = tenant.omniauth_login_path
        # TODO: don't hard-code this
        expect(login_path).to eq('https://localhost/Shibboleth.sso/Login?target=https%3A%2F%2Flocalhost%2Fstash%2Fauth%2Fshibboleth%2Fcallback&entityID=urn%3Amace%3Aincommon%3Aucop.edu')
      end
    end

    describe :logo_file do
      it 'returns the tenant file if it exists' do
        tenant = Tenant.find('ucop')
        logo_filename = "logo_#{tenant.tenant_id}.svg"
        expect(tenant.logo_file).to eq(logo_filename)
      end
    end

    describe :shibboleth_login_path do
      it 'returns the login path' do
        tenant = Tenant.find('ucop')
        login_path = tenant.shibboleth_login_path
        expect(login_path).to eq('https://localhost/Shibboleth.sso/Login?target=https%3A%2F%2Flocalhost%2Fstash%2Fauth%2Fshibboleth%2Fcallback&entityID=urn%3Amace%3Aincommon%3Aucop.edu')
      end
    end

    describe :full_url do
      it 'builds a full URL from a tenant' do
        tenant = Tenant.find('ucop')
        expect(tenant.full_url('/doi:10.123/456')).to eq('https://localhost:3000/doi:10.123/456')
      end
    end

    describe :exists? do
      it 'checks if a tenant exists' do
        expect(Tenant.exists?('ucop')).to be true
        expect(Tenant.exists?('pustule')).to be false
      end
    end

  end
end
