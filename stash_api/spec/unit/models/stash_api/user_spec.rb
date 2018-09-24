require 'db_spec_helper'
require 'factory_helper'
require 'byebug'
# require 'test_helper'

# something wacky about our setup requires this here.  It seems to be either a) never requiring them or b) requiring them 1000 times otherwise
# FactoryBot.find_definitions

module StashApi
  RSpec.describe User do
    before(:each) do

      # all these doubles are required because I can't get a url helper for creating URLs inside the tests!  Ick.
      generic_path = double('generic_path')
      allow(generic_path).to receive(:user_path).and_return('user_path') # with id
      allow(generic_path).to receive(:users_path).and_return('users_path') # without id

      allow(User).to receive(:api_url_helper).and_return(generic_path)

      @user = create(:user)

    end

    # this is just a basic test to be sure FactoryBot works.  It likes to break a lot.
    describe :factories do
      it 'creates a FactoryBot factory that works' do
        expect(@user).to be_valid
      end
    end

    describe :basic_user_view do

      before(:each) do
        @user = User.new(user_id: @user.id)
        @metadata = @user.metadata
      end

      it 'has a valid name' do
        expect(@metadata[:firstName]).to eq('Juanita')
        expect(@metadata[:lastName]).to eq('Collins')
      end

      it 'has a valid email' do
        expect(@metadata[:email]).to eq('juanita.collins@example.org')
      end

      it 'has a valid tenantId' do
        expect(@metadata[:tenantId]).to eq('exemplia')
      end

      it 'has a valid role' do
        expect(@metadata[:role]).to eq('user')
      end

      it 'has a valid orcid' do
        expect(@metadata[:orcid]).to eq('1098-415-1212')
      end

      it 'has a valid oldDryadEmail' do
        expect(@metadata[:oldDryadEmail]).to eq('lolinda@example.com')
      end

      it 'has a valid ePersonId' do
        expect(@metadata[:ePersonId]).to eq(37)
      end

      it 'has a valid created time' do
        expect(@metadata[:createdAt]).to be_within(10.seconds).of(Time.now)
      end

    end

  end
end
