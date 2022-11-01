module StashEngine
  RSpec.describe AdminDatasetFundersController, type: :request do

    # https://github.com/bobf/rspec-html might be helpful if I want more complex matching of document returned

    include Mocks::Tenant

    before(:each) do
      mock_tenant!
      @user = create(:user, role: 'superuser')
      # HACK: in session because requests specs don't allow session in rails 4
      allow_any_instance_of(AdminDatasetFundersController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

      @resources = 5.times.map do |i|
        create(:resource)
      end
    end

    describe 'general information' do
      it 'outputs basic information about title, author, doi, funder and award' do
        response_code = get '/stash/ds_admin_funders'
        expect(response_code).to eq(200)

        @resources.each do |res|
          expect(body).to include(res.title)
          expect(body).to include(res.authors.first.author_last_name)
          expect(body).to include(res.identifier.identifier)
          expect(body).to include(res.contributors.first.contributor_name)
          expect(body).to include(res.contributors.first.award_number)
        end
      end

      it 'shows a submission date' do

      end

      it 'shows an embargo date' do

      end

      it 'shows a publication date' do

      end
    end

    describe 'limit report to partner institution' do
      before(:each) do
        @resources.first.update(tenant_id: 'dataone')
        @resources.second.update(tenant_id: 'dryad')
      end

      it 'limits by partner institution' do
        response_code = get '/stash/ds_admin_funders', params: { tenant: 'dryad' }
        expect(response_code).to eq(200)
        expect(body).to include(@resources.second.title)
        expect(body).not_to include(@resources.first.title)
      end
    end

  end
end
