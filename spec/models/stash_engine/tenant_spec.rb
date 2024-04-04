require 'tmpdir'
require 'fileutils'

module StashEngine
  describe Tenant, type: :model do

    before(:each) do
      create(:tenant_dryad)
      create(:tenant_ucop)
    end

    describe :logo_file do
      it 'returns the tenant file if it exists' do
        tenant = Tenant.find('ucop')
        logo_filename = "logo_#{tenant.id}.svg"
        expect(tenant.logo_file).to eq(logo_filename)
      end
    end

    describe :authentication do
      it 'parses authentication' do
        tenant = Tenant.find('ucop')
        expect(tenant.authentication.strategy).to eq('shibboleth')
      end
    end

    describe :campus_contacts do
      it 'parses campus contacts' do
        tenant = Tenant.find('dryad')
        expect(tenant.campus_contacts).not_to be_empty
      end
    end

    describe :ror_ids do
      it 'lists associated ROR IDs' do
        create_list(:tenant_ror_org, 2, tenant_id: 'dryad')
        tenant = Tenant.find('dryad')
        expect(tenant.ror_ids.count).to eq 3
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

  end
end
