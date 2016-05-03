require 'spec_helper'

module Stash
  module Sword2
    describe Client do
      it 'can be instantiated' do
        client = Client.new
        expect(client).to be_a(Client)
      end
    end
  end
end
