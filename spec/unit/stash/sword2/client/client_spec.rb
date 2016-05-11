require 'spec_helper'

module Stash
  module Sword2
    describe Client do
      it 'can be instantiated' do
        client = Client.new(username: 'elvis', password: 'presley')
        expect(client).to be_a(Client)
      end

    end
  end
end
