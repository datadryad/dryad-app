module StashEngine
  RSpec.describe AdminDatasetsController, type: :request do
    include Mocks::Salesforce

    before do
      mock_salesforce!
    end

    describe '#destroy' do
      let!(:tenant) { create(:tenant) }
      let(:resource) { create(:resource) }
      let(:identifier) { resource.identifier }

      subject { delete ds_admin_destroy_path(identifier.id) }

      before do
        allow_any_instance_of(AdminDatasetsController).to receive(:session).and_return({ user_id: user.id }.to_ostruct)
        allow_any_instance_of(AdminDashboardController).to receive(:session).and_return({ user_id: user.id }.to_ostruct)
        allow_any_instance_of(DashboardController).to receive(:session).and_return({ user_id: user.id }.to_ostruct)
      end

      context 'as superuser' do
        let!(:user) { create(:user, role: 'superuser', tenant_id: 'dryad') }

        context 'when identifier can be deleted' do
          it 'deletes the resource and identifier' do
            allow_any_instance_of(Stash::Aws::S3).to receive(:delete_dir).and_return(true)
            subject

            expect(response).to have_http_status(302)
            expect(response.headers['Location']).to eq(admin_dashboard_url)
            follow_redirect!
            expect(response.body).to include("Dataset with DOI #{identifier.identifier} has been deleted.")
          end
        end

        context 'when dataset status changed' do
          before do
            create(:curation_activity, status: 'processing', user: resource.submitter, resource: resource)
          end

          it 'does not delete the resource and identifier' do
            subject

            expect(response).to have_http_status(302)
            expect(response.headers['Location']).to include(choose_dashboard_url)
            expect(controller.flash[:alert]).to eq('You are not authorized to view this information.')
          end
        end

        context 'when identifier destroy fails' do
          before do
            expect_any_instance_of(StashEngine::Identifier).to receive(:destroy).and_return(false)
          end

          it 'does not delete the resource and identifier' do
            subject

            expect(response).to have_http_status(302)
            expect(response.headers['Location']).to eq(activity_log_url(identifier.id))
            expect(controller.flash[:alert]).to eq('Dataset could not be deleted. Please try again later.')
          end
        end
      end

      context 'as curator' do
        let(:user) { create(:user, role: 'curator', tenant_id: 'dryad') }

        it 'can not delete the resource and identifier' do
          subject

          expect(response).to have_http_status(302)
          expect(response.headers['Location']).to include(choose_dashboard_url)
          expect(controller.flash[:alert]).to eq('You are not authorized to view this information.')
        end
      end

      context 'as an admin' do
        let(:user) { create(:user, role: 'admin', tenant_id: 'dryad') }

        it 'can not delete the resource and identifier' do
          subject

          expect(response).to have_http_status(302)
          expect(response.headers['Location']).to include(choose_dashboard_path)
          expect(controller.flash[:alert]).to eq('You are not authorized to view this information.')
        end
      end
    end
  end
end
