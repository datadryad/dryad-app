module StashEngine
  RSpec.describe SessionsController, type: :request do

    describe '#sso-ip_address' do
      it 'allows user in with allowed IP address' do
        @user = create(:user, role: 'user', tenant_id: 'dryad_ip')
        allow_any_instance_of(SessionsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

        response_code = post '/stash/sessions/sso', params: { 'tenant_id' => 'dryad_ip' }
        expect(response_code).to eql(302) # redirect
        expect(response.headers['Location']).to include('/stash/dashboard')
      end

      it 'blocks user from non-allowed IP address' do
        create(:tenant_ip, authentication: { strategy: 'ip_address', ranges: ['192.168.1.0/255.255.255.0'] }.to_json)
        @user = create(:user, role: 'user', tenant_id: 'dryad_ip')
        allow_any_instance_of(SessionsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

        response_code = post '/stash/sessions/sso', params: { 'tenant_id' => 'dryad_ip' }
        expect(response_code).to eql(302) # redirect
        expect(response.headers['Location']).to include('/stash/ip_error')
      end
    end
  end
end
