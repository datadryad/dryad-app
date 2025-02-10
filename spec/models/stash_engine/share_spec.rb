# == Schema Information
#
# Table name: stash_engine_shares
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  identifier_id :integer
#  resource_id   :integer
#  secret_id     :string(191)
#
# Indexes
#
#  index_stash_engine_shares_on_identifier_id  (identifier_id)
#  index_stash_engine_shares_on_secret_id      (secret_id)
#
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
        expect(@share.sharing_link).to start_with('http')
        expect(@share.sharing_link).to include('/share/')
        expect(@share.sharing_link).to include('http')
      end

      it 'creates a share if an identifier is created' do
        expect(@identifier.shares.count).to be > 0
      end
    end

  end
end
