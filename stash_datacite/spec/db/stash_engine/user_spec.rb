require 'spec_helper'
require 'ostruct'
require 'byebug'

module StashEngine
  describe User do

    context :affiliation do

      before(:each) do
        # I don't see any factories here, so just creating a resource manually
        @user = StashEngine::User.create(
          first_name: 'Lisa',
          last_name: 'Muckenhaupt',
          email: 'lmuckenhaupt@ucop.edu',
          tenant_id: 'ucop'
        )
        @affiliation = StashDatacite::Affiliation.create(
          short_name: 'Testing',
          abbreviation: 'TEST',
          ror_id: '1234'
        )
      end

      it 'can be assigned' do
        expect(@user.affiliation).to eql(nil)
        @user.affiliation = @affiliation
        expect(@user.affiliation).to eql(@affiliation)
      end

    end

  end
end
