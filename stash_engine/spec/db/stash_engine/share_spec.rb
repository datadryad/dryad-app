require 'db_spec_helper'

module StashEngine
  describe Share do
    attr_reader :user
    attr_reader :identifier
    attr_reader :share

    before(:each) do
      @share = Share.create(identifier_id: identifier.id)
    end

    describe :identifier do
      it 'returns the identifier' do
        expect(share.identifier).to eq(identifier)
      end
    end

    describe :sharing_link do
      it 'returns the sharing link' do
        url_helpers = double(Module)
        routes = double(Module)
        allow(routes).to receive(:url_helpers).and_return(url_helpers)
        allow(StashEngine::Engine).to receive(:routes).and_return(routes)

        sharing_url = 'https://example.org/1234'
        expect(url_helpers).to receive(:share_url).with(protocol: 'https', id: share.secret_id).and_return(sharing_url)
        expect(share.sharing_link).to eq(sharing_url)
      end
    end

  end
end
