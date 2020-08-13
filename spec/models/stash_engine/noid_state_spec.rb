module StashEngine
  describe NoidState do
    before(:each) do
      NoidState.destroy_all
    end

    describe :mint do
      it 'mints in predictable way from saved state' do
        id1 = NoidState.mint
        id2 = NoidState.mint
        id3 = NoidState.mint
        expect(id1).to eq('4qrfj6q5t')
        expect(id2).to eq('x95x69pcr')
        expect(id3).to eq('5qfttdz10')
      end
    end
  end
end
