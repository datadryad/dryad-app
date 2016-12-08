require 'db_spec_helper'

module StashEngine
  describe User do
    attr_reader :user

    # before(:each) do
    #   @user = User.create(
    #     uid: 'lmuckenhaupt-ucop@ucop.edu',
    #     first_name: 'Lisa',
    #     last_name: 'Muckenhaupt',
    #     email: 'lmuckenhaupt@ucop.edu',
    #     provider: 'developer',
    #     tenant_id: 'ucop'
    #   )
    # end

    describe '#from_omniauth' do
      it 'creates a user' do
        auth = {
          provider: 'google_oauth2',
          uid: 'lmuckenhaupt-ucop@ucop.edu',
          info: {
            email: 'lmuckenhaupt@ucop.edu',
            name: 'Lisa Muckenhaupt'
          },
          credentials: {
            token: '1234567890'
          },
        }.to_ostruct
        user = User.from_omniauth(auth, 'ucop')
        expect(user).to be_a(User)
        expect(user).to be_persisted
        expect(user.uid).to eq('lmuckenhaupt-ucop@ucop.edu')
        expect(user.first_name).to eq('Lisa')
        expect(user.last_name).to eq('Muckenhaupt')
        expect(user.email).to eq('lmuckenhaupt@ucop.edu')
        expect(user.provider).to eq('google_oauth2')
        expect(user.tenant_id).to eq('ucop')
        expect(user.oauth_token).to eq('1234567890')
      end
    end
  end
end
