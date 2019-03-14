module Mocks

  module Ezid

    def mock_minting!
      # require 'stash/stash_engine/lib/stash/doi/ezid_gen.rb'
      allow_any_instance_of(Stash::Doi::EzidGen).to receive(:mint_id).and_return('doi:12234/38575')
    end

  end

end
