require 'db_spec_helper'
require_relative '../../../../spec_helpers/factory_helper'

module StashEngine
  describe Share do

    before(:each) do
      @identifier = create(:identifier)
    end

    describe :identifier do
      it 'returns the identifier' do
        @share = Share.create(identifier_id: @identifier.id)
        expect(@share.identifier).to eq(@identifier)
      end
    end

    describe :sharing_link do
      it 'returns the sharing link' do
        @share = Share.create(identifier_id: @identifier.id)
        url_helpers = double(Module)
        routes = double(Module)
        allow(routes).to receive(:url_helpers).and_return(url_helpers)
        allow(StashEngine::Engine).to receive(:routes).and_return(routes)

        sharing_url = 'https://example.org/1234'
        expect(url_helpers).to receive(:share_url).with(protocol: 'https', id: @share.secret_id).and_return(sharing_url)
        expect(@share.sharing_link).to eq(sharing_url)
      end

      it 'creates a share if an identifier is created' do
        expect(@identifier.shares.count).to eql(1)
      end
    end

  end
end
