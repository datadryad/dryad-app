require 'db_spec_helper'

module StashEngine
  describe Share do
    attr_reader :user
    attr_reader :resource
    attr_reader :tenant
    attr_reader :share

    before(:each) do
      @resource = Resource.create(tenant_id: 'ucop')
      @tenant = double(Tenant)
      allow(Tenant).to receive(:find).with('ucop').and_return(tenant)

      @share = Share.create(resource_id: resource.id)
    end

    describe :resource do
      it 'returns the resource' do
        expect(share.resource).to eq(resource)
      end
    end

    describe :tenant do
      it 'returns the resource tenant' do
        expect(share.tenant).to be(tenant)
      end
    end

    describe :sharing_link do
      it 'returns the sharing link' do
        url_helpers = double(Module)
        routes = double(Module)
        allow(routes).to receive(:url_helpers).and_return(url_helpers)
        allow(StashEngine::Engine).to receive(:routes).and_return(routes)

        full_domain = 'example.org'
        allow(tenant).to receive(:full_domain).and_return(full_domain)
        sharing_url = 'https://example.org/1234'
        expect(url_helpers).to receive(:share_url).with(host: full_domain, protocol: 'https', id: share.secret_id).and_return(sharing_url)
        expect(share.sharing_link).to eq(sharing_url)
      end
    end

  end
end
