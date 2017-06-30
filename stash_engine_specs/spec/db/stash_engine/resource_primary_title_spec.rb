require 'db_spec_helper'

module StashEngine
  describe Resource do

    attr_reader :user

    before(:each) do
      @user = StashEngine::User.create(
        uid: 'lmuckenhaupt-ucop@ucop.edu',
        first_name: 'Lisa',
        last_name: 'Muckenhaupt',
        email: 'lmuckenhaupt@ucop.edu',
        provider: 'developer',
        tenant_id: 'ucop'
      )
    end

    describe :primary_title do
      it 'is abstract' do
        resource = Resource.create(user_id: user.id)
        expect { resource.primary_title }.to raise_error(NameError)
      end
    end
  end
end
