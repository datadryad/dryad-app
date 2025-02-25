module StashEngine
  RSpec.describe SessionsController, type: :request do

    describe '#sso-ip_address' do
      it 'allows user in with allowed IP address' do
        @user = create(:user, tenant_id: 'dryad_ip')
        allow_any_instance_of(SessionsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

        response_code = post '/sessions/sso', params: { tenant_id: { value: 'dryad_ip' } }
        expect(response_code).to eql(302) # redirect
        expect(response.headers['Location']).to include('/choose_dashboard')
      end

      it 'blocks user from non-allowed IP address' do
        create(:tenant_ip, authentication: { strategy: 'ip_address', ranges: ['192.168.1.0/255.255.255.0'] }.to_json)
        @user = create(:user, tenant_id: 'dryad_ip')
        allow_any_instance_of(SessionsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

        response_code = post '/sessions/sso', params: { tenant_id: { value: 'dryad_ip' } }
        expect(response_code).to eql(302) # redirect
        expect(response.headers['Location']).to include('/ip_error')
      end

      it 'sets default tenant_id on chose sso page' do
        create(:tenant_ucop, partner_display: true, authentication: { strategy: 'ip_address', ranges: ['127.0.0.1/255.255.255.0'] }.to_json)
        @user = create(:user, tenant_id: nil)
        allow_any_instance_of(SessionsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
        allow_any_instance_of(SessionsController).to receive(:current_tenant).and_return(nil)

        response_code = get '/sessions/choose_sso'
        expect(response_code).to eql(200) # no redirect
        expect(@user.reload.tenant_id).to eql(APP_CONFIG.default_tenant)
      end
    end
  end
end
