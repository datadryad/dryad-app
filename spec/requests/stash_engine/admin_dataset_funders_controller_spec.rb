require 'cgi'
module StashEngine
  RSpec.describe AdminDatasetFundersController, type: :request do

    # https://github.com/bobf/rspec-html might be helpful if I want more complex matching of document returned

    context :tenant_limited do

      before(:each) do
        create(:tenant)
        @user = create(:user, tenant_id: 'dryad')
        create(:role, user: @user, role_object: @user.tenant)
        # HACK: in session because requests specs don't allow session in rails 4
        allow_any_instance_of(AdminDatasetFundersController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
        @resources = 5.times.map do |_i|
          create(:resource)
        end
      end

      describe 'limit report to tenant institution' do
        before(:each) do
          @resources.first.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2011, 11, 11, 12))
          @resources.second.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2006, 6, 6, 12))
          @resources.third.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2006, 6, 6, 12))
          @resources.first.update(tenant_id: 'dryad')
          @resources.second.update(tenant_id: 'mock_tenant')
          @resources.third.update(tenant_id: 'dryad')
        end

        it 'limits to tenant institution' do
          response_code = get '/ds_admin_funders'
          expect(response_code).to eq(200)
          expect(body).to include(CGI.escapeHTML(@resources.first.title))
          expect(body).to include(CGI.escapeHTML(@resources.third.title))
          expect(body).not_to include(CGI.escapeHTML(@resources.second.title))
        end
      end
    end

    context :with_superuser do

      before(:each) do
        @user = create(:user, role: 'superuser')
        # HACK: in session because requests specs don't allow session in rails 4
        allow_any_instance_of(AdminDatasetFundersController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)

        @resources = 5.times.map do |_i|
          create(:resource)
        end
      end

      describe 'general information' do
        before(:each) do
          @resources.each { |res| res.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2006, 6, 6, 12)) }
        end
        it 'outputs basic information about title, author, doi, funder and award' do
          response_code = get '/ds_admin_funders'
          expect(response_code).to eq(200)

          @resources.each do |res|
            expect(body).to include(CGI.escapeHTML(res.title))
            expect(body).to include(CGI.escapeHTML(res.authors.first.author_last_name))
            expect(body).to include(CGI.escapeHTML(res.identifier.identifier))
            expect(body).to include(CGI.escapeHTML(res.contributors.first.contributor_name))
            expect(body).to include(CGI.escapeHTML(res.contributors.first.award_number))
          end
        end

        it 'shows the submission date' do
          response_code = get '/ds_admin_funders'
          expect(response_code).to eq(200)
          expect(body).to include('Jun 06, 2006')
        end

        it 'shows an embargo date' do
          res = @resources.first
          res.identifier.update(pub_state: 'embargoed')
          res.update(meta_view: true, publication_date: Time.new(2291, 10, 11, 12))
          response_code = get '/ds_admin_funders'
          expect(response_code).to eq(200)
          expect(body).to include('Oct 11, 2291')
        end

        it 'shows a publication date' do
          res = @resources.first
          res.identifier.update(pub_state: 'published')
          res.update(meta_view: true, file_view: true, publication_date: Time.new(2021, 3, 17, 12))
          response_code = get '/ds_admin_funders'
          expect(response_code).to eq(200)
          expect(body).to include('Mar 17, 2021')
        end
      end

      describe 'limit report to partner institution' do
        before(:each) do
          @resources.first.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2011, 11, 11, 12))
          @resources.second.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2006, 6, 6, 12))
          @resources.first.update(tenant_id: 'dataone')
          @resources.second.update(tenant_id: 'dryad')
        end

        it 'limits by partner institution' do
          response_code = get '/ds_admin_funders', params: { tenant: 'dryad' }
          expect(response_code).to eq(200)
          expect(body).to include(CGI.escapeHTML(@resources.second.title))
          expect(body).not_to include(CGI.escapeHTML(@resources.first.title))
        end
      end

      describe 'limit report to funder' do
        before(:each) do
          @resources.first.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2011, 11, 11, 12))
          @resources.second.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2006, 6, 6, 12))
        end

        it 'limits to a single, simple funder (not NIH)' do
          response_code = get '/ds_admin_funders', params: { funder_name: @resources.first.contributors.first.contributor_name }
          expect(response_code).to eq(200)
          expect(body).to include(CGI.escapeHTML(@resources.first.title))
          expect(body).not_to include(CGI.escapeHTML(@resources.second.title))
        end

        it 'limits to a compound funder with sub-units' do
          create(:contributor_grouping) # sets up example NIH sub-units
          @resources.first.contributors.first.update(contributor_name: 'National Institute on Minority Health and Health Disparities',
                                                     name_identifier_id: 'http://dx.doi.org/10.13039/100006545')
          @resources.second.contributors.first.update(
            contributor_name: 'Eunice Kennedy Shriver National Institute of Child Health and Human Development',
            name_identifier_id: 'http://dx.doi.org/10.13039/100009633'
          )

          cg = StashDatacite::ContributorGrouping.first
          response_code = get '/ds_admin_funders', params: { funder_name: cg.contributor_name, funder_id: cg.name_identifier_id }
          expect(response_code).to eq(200)

          expect(body).to include(CGI.escapeHTML(@resources[0].title))
          expect(body).to include(CGI.escapeHTML(@resources[1].title))
          expect(body).not_to include(CGI.escapeHTML(@resources[2].title))
        end
      end

      describe 'limit to dates' do
        before(:each) do
          @resources.first.resource_states.first.update(resource_state: 'submitted', updated_at: Time.new(2011, 11, 11, 12))
        end

        it 'limits to an initial submission date' do
          response_code = get '/ds_admin_funders', params: { date_type: 'initial',
                                                             start_date: '2011-11-01',
                                                             end_date: '2011-12-01' }
          expect(response_code).to eq(200)
          expect(body).to include('Nov 11, 2011')
          expect(body).to include(CGI.escapeHTML(@resources[0].title))
          expect(body).not_to include(CGI.escapeHTML(@resources[2].title))
        end

        it 'limits to an embargo/publication date' do
          res = @resources.first
          res.identifier.update(pub_state: 'published')
          res.update(meta_view: true, file_view: true, publication_date: Time.new(2016, 8, 22, 12))
          response_code = get '/ds_admin_funders', params: { date_type: 'published',
                                                             start_date: '2016-08-01',
                                                             end_date: '2016-09-01' }
          expect(response_code).to eq(200)
          expect(body).to include('Aug 22, 2016')
          expect(body).to include(CGI.escapeHTML(@resources[0].title))
          expect(body).not_to include(CGI.escapeHTML(@resources[1].title))
        end
      end
    end
  end
end
