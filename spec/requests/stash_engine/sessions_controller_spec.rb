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

    describe '#email_validate' do
      let(:valid_email) { false }
      let!(:user) { create(:user, tenant_id: 'dryad_ip', validated: valid_email) }

      before do
        allow_any_instance_of(SessionsController).to receive(:session).and_return({ user_id: user.id }.to_ostruct)
      end
      subject { get email_validate_path }

      context 'when email is not validated' do
        it 'creates a new token' do
          expect { subject }.to change { StashEngine::EmailToken.count }.by(1)
          expect(user.email_token).not_to be_nil
        end
      end

      context 'when email is already validated' do
        let(:valid_email) { true }

        it 'does not create a new token' do
          subject

          expect(user).to receive(:create_email_token).never
        end
      end

      context 'when refresh param is set' do
        subject { get email_validate_path(refresh: true) }

        it 'creates a new token' do
          expect { subject }.to change { StashEngine::EmailToken.count }.by(1)
          expect(user.email_token).not_to be_nil
        end
      end
    end
  end
end
