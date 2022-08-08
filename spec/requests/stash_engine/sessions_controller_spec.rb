module StashEngine
  RSpec.describe SessionsController, type: :request do
    include Mocks::Tenant

    describe '#sso-ip_address' do
      it 'allows user in with allowed IP address' do
        mock_ip_tenant!(ip_string: '127.0.0.1/255.255.255.0')
        @user = create(:user, role: 'user')
        allow_any_instance_of(SessionsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

        response_code = post '/stash/sessions/sso', params: { 'tenant_id' => nil } # tenant mock means not needed
        expect(response_code).to eql(302) # redirect
        expect(response.headers['Location']).to include('/stash/dashboard')
      end

      it 'blocks user from non-allowed IP address' do
        mock_ip_tenant!(ip_string: '192.168.1.0/255.255.255.0')
        @user = create(:user, role: 'user')
        allow_any_instance_of(SessionsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

        response_code = post '/stash/sessions/sso', params: { 'tenant_id' => nil } # tenant mock means not needed
        expect(response_code).to eql(302) # redirect
        expect(response.headers['Location']).to include('/stash/ip_error')
      end
    end
  end
end
