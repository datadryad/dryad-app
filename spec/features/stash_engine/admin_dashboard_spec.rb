require 'pry-remote'

RSpec.feature 'AdminDashboard', type: :feature do
  include DatasetHelper
  include Mocks::Aws
  include Mocks::Repository
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::DataFile

  before(:each) do
    mock_aws!
    mock_solr!
    mock_salesforce!
    mock_stripe!
    mock_repository!
    mock_datacite!
    mock_file_content!
    neuter_curation_callbacks!
  end

  context :fields_and_filters do
    before(:each) do
      create(:tenant)
      @user = create(:user, tenant_id: 'test_tenant')
      @superuser = create(:user, role: 'superuser')
      3.times do
        identifier = create(:identifier)
        create(:resource, :submitted, publication_date: nil, user: @user, identifier: identifier)
      end
      sign_in(@superuser, false)
    end

    it 'has admin links for superuser', js: true do
      visit root_path
      click_button 'Datasets'
      expect(page).to have_link('Admin dashboard')
      expect(page).to have_link('Status dashboard')
      expect(page).to have_link('Submission queue')
    end

    it 'shows fields in html output', js: true do
      visit stash_url_helpers.admin_dashboard_path
      expect(page).to have_text('Admin dashboard')
      check 'submitter'
      check 'metrics'
      click_button('Apply')
      expect(find('thead')).to have_text('Submitter')
      expect(find('thead')).to have_text('Metrics')
    end

    it 'shows fields in csv output' do
      visit stash_url_helpers.admin_dashboard_path
      expect(page).to have_text('Admin dashboard')
      check 'submitter'
      check 'metrics'
      click_button('Apply')
      # must visit instead of clicking link; adding js: true breaks ability to load CSV
      visit stash_url_helpers.admin_dashboard_results_path(format: :csv)
      csv_line = page.body.split("\n").first
      csv_parts = csv_line.split(',')
      expect(csv_parts).to include('Submitter', 'Metrics')
    end

    it 'has 2 search fields', js: true do
      visit stash_url_helpers.admin_dashboard_path
      expect(page).to have_text('Admin dashboard')
      expect(page).to have_field('search-string')
      expect(page).to have_field('related-search')
    end

    context :date_and_state_filters do
      before(:each) do
        StashEngine::Resource.submitted.first.curation_activities.last.update(updated_at: Date.today + 2.days)
        StashEngine::Resource.submitted.last.curation_activities << StashEngine::CurationActivity.create(status: 'curation', user_id: @superuser.id)
        2.times do
          identifier = create(:identifier)
          create(:resource, publication_date: nil, user: @user, identifier: identifier)
        end
        3.times do
          identifier = create(:identifier)
          create(:resource_published, user: @user, identifier: identifier)
        end
        3.times do
          identifier = create(:identifier)
          create(:resource_embargoed, user: @user, identifier: identifier)
        end
      end

      it 'filters on status', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        select('In progress', from: 'filter-status')
        click_button('Apply')
        assert_selector('tbody tr', count: 2)
        select('Submitted', from: 'filter-status')
        click_button('Apply')
        assert_selector('tbody tr', count: 2)
        select('Curation', from: 'filter-status')
        click_button('Apply')
        assert_selector('tbody tr', count: 1)
        select('Published', from: 'filter-status')
        click_button('Apply')
        assert_selector('tbody tr', count: 3)
        select('Embargoed', from: 'filter-status')
        click_button('Apply')
        assert_selector('tbody tr', count: 3)
      end

      it 'filters on last modified date', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        fill_in('updated_atstart', with: I18n.l(Date.today + 1.day, format: '%d-%m-%Y'))
        click_button('Apply')
        assert_selector('tbody tr', count: 1)
      end

      it 'filters on submitted date', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        fill_in('submit_datestart', with: I18n.l(Date.today - 1.day, format: '%d-%m-%Y'))
        click_button('Apply')
        assert_selector('tbody tr', count: 9)
      end

      it 'filters on published date', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        fill_in('publication_datestart', with: I18n.l(Date.today - 1.day, format: '%d-%m-%Y'))
        click_button('Apply')
        assert_selector('tbody tr', count: 6)
        fill_in('publication_dateend', with: I18n.l(Date.today, format: '%d-%m-%Y'))
        click_button('Apply')
        assert_selector('tbody tr', count: 3)
      end
    end
  end

  context :roles do
    before(:each) do
      create(:tenant)
      @admin = create(:user, tenant_id: 'test_tenant')
      create(:role, user: @admin, role_object: @admin.tenant)
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id, skip_datacite_update: true)
    end

    context :app_admin, js: true do
      before(:each) do
        create(:role, user: @user, role: 'admin')
        sign_in(@user, false)
      end

      it 'shows limited menus to an administrative curator', js: true do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
        expect(page).to have_link('Curation stats')
        expect(page).to have_link('Journals')
        expect(page).not_to have_link('User management')
        expect(page).not_to have_link('Submission queue')
      end

      it 'has all filters for system users', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard'
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_select('filter-member')
        expect(page).to have_select('filter-status')
        expect(page).to have_select('filter-curator')
        expect(page).to have_field('searchselect-journal__input')
        expect(page).to have_select('filter-sponsor')
        expect(page).to have_field('searchselect-funder__input')
        expect(page).to have_field('searchselect-affiliation__input')
        expect(page).to have_field('updated_atstart')
        expect(page).to have_field('submit_datestart')
        expect(page).to have_field('publication_datestart')
      end

      it 'limits options in the dashboard', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard'
        visit stash_url_helpers.admin_dashboard_path

        expect(page).to have_content(@resource.title)
        expect(page).not_to have_selector('button.c-admin-edit-icon .fa-pencil') # no pencil editing icons for you
      end
    end

    context :curator, js: true do
      before(:each) do
        create(:curation_activity_no_callbacks, status: 'curation', user_id: @user.id, resource_id: @resource.id)
        @resource.resource_states.first.update(resource_state: 'submitted')
        sign_in(create(:user, role: 'curator'))
        visit stash_url_helpers.admin_dashboard_path(curation_status: 'curation')
      end

      it 'has admin link', js: true do
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
        expect(page).to have_link('Publication updater')
      end

      it 'selects identifiers and curator fields by default', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(find('#identifiers')).to be_checked
        expect(find('thead')).to have_text('Publication IDs')
        expect(find('#curator')).to be_checked
        expect(find('thead')).to have_text('Curator')
      end

      # actions

      # it 'filters on curator', js:true do; end

    end

    context :tenant_curator, js: true do
      before(:each) do
        @tenant_curator = create(:user, role: 'curator', role_object: @admin.tenant, tenant_id: @admin.tenant_id)
        sign_in(@tenant_curator, false)
      end

      it 'has admin link', js: true do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target institution', js: true do
        ident1 = create(:identifier)
        res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @tenant_curator.tenant_id)
        ident2 = create(:identifier)
        user2 = create(:user, tenant_id: 'bad_tenant')
        res2 = create(:resource, identifier_id: ident2.id, user: user2, tenant_id: user2.tenant_id)

        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard'
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects affiliations field by default', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard'
        visit stash_url_helpers.admin_dashboard_path
        expect(find('#affiliations')).to be_checked
      end
    end

    context :tenant_admin do
      before(:each) do
        sign_in(@admin)
      end

      it 'has admin link', js: true do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target institution', js: true do
        ident1 = create(:identifier)
        res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
        ident2 = create(:identifier)
        user2 = create(:user, tenant_id: 'bad_tenant')
        res2 = create(:resource, identifier_id: ident2.id, user: user2, tenant_id: user2.tenant_id)

        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard'
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects affiliations field by default', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(find('#affiliations')).to be_checked
      end

      it 'Limits options in the dashboard', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard'
        visit stash_url_helpers.admin_dashboard_path

        expect(page).to have_content(@resource.title)
        expect(page).not_to have_selector('button.c-admin-edit-icon .fa-pencil') # no pencil editing icons for you
      end

      it 'does not allow editing a dataset from the dashboard', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard'
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(page).not_to have_css('button[title="Edit dataset"]')
      end
    end

    context :consortia do
      before(:each) do
        # Create a user, identifier and 2 resources for each tenant
        %w[ucop dryad mock_tenant].each do |tenant|
          user = create(:user, tenant_id: tenant)
          2.times do
            identifier = create(:identifier)
            @res1 = create(:resource, :submitted, user: user, identifier: identifier)
          end
        end
        @consortium = create(:tenant, id: 'consortium', short_name: 'Consortium', long_name: 'Consortium')
        # Create user, identifier, and 2 resources for consortium
        %w[member1 member2].each do |member|
          create(:tenant, id: member, short_name: member, sponsor_id: 'consortium')
          user = create(:user, tenant_id: member)
          2.times do
            identifier = create(:identifier)
            @res2 = create(:resource, :submitted, user: user, identifier: identifier)
          end
        end
        sign_in(create(:user, role: 'admin', role_object: @consortium, tenant_id: 'consortium'))
      end

      it 'shows only datasets for consortium tenants', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        assert_selector('tbody tr', count: 4)
        expect(page).to have_text(@res2.title)
        expect(page).not_to have_text(@res1.title)
      end

      it 'shows consortium admins dropdown for their tenants', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_select('filter-member')
        expect(page).to have_selector('#filter-member option', count: 4)
      end

      it 'filters by tenant', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        select('member1', from: 'filter-member')
        click_button('Apply')
        assert_selector('tbody tr', count: 2)
        expect(find('#search_results')).to have_text('member1', count: 2)
      end
    end

    context :journal_admin, js: true do
      before(:each) do
        @journal = create(:journal)
        @journal_admin = create(:user, tenant_id: 'mock_tenant')
        @journal_role = create(:role, role_object: @journal, user: @journal_admin)
        @journal_admin.reload
        sign_in(@journal_admin, false)
        ident1 = create(:identifier)
        @res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
        StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationISSN', value: @journal.single_issn)
        StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationName', value: @journal.title)
        ident1.reload
      end

      it 'has admin link', js: true do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target journal', js: true do
        ident2 = create(:identifier)
        res2 = create(:resource, identifier_id: ident2.id, user: @user, tenant_id: @admin.tenant_id)

        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(@res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects identifiers field by default', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(find('#identifiers')).to be_checked
        expect(find('thead')).to have_text('Publication IDs')
      end
    end

    context :sponsor_admin, js: true do
      before(:each) do
        @org = create(:journal_organization)
        @sponsor_admin = create(:user)
        create(:role, role_object: @org, user: @sponsor_admin)
        3.times do
          @journal = create(:journal, sponsor_id: @org.id)
          2.times do
            ident1 = create(:identifier)
            @res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
            StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationISSN', value: @journal.single_issn)
            StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationName', value: @journal.title)
            ident1.reload
          end
        end
        sign_in(@sponsor_admin, false)
      end

      it 'has admin link', js: true do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target journals', js: true do
        ident2 = create(:identifier)
        res2 = create(:resource, identifier_id: ident2.id, user: @user, tenant_id: @admin.tenant_id)

        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        assert_selector('tbody tr', count: 6)
        expect(page).to have_text(@res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects journal field by default', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(find('#journal')).to be_checked
        expect(find('thead')).to have_text('Journal')
      end

      it 'shows sponsor admins dropdown for their journals', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_select('filter-journal')
        expect(page).to have_selector('#filter-journal option', count: 4)
      end

      it 'filters by journal', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        select(@journal.title, from: 'filter-journal')
        click_button('Apply')
        assert_selector('tbody tr', count: 2)
        expect(find('#search_results')).to have_text(@journal.title, count: 2)
      end
    end

    context :funder_admin, js: true do
      before(:each) do
        @res1 = create(:resource, user: @user)
        @contributor = create(:contributor, resource: @res1)
        res = create(:resource, user: @user)
        create(:contributor, resource: res, contributor_name: @contributor.contributor_name, name_identifier_id: @contributor.name_identifier_id)
        funder = create(:funder, name: @contributor.contributor_name, ror_id: @contributor.name_identifier_id)
        @funder_admin = create(:user, tenant_id: 'mock_tenant')
        @funder_role = create(:role, role_object: funder, user: @funder_admin)
        @funder_role.reload
        @funder_admin.reload
        sign_in(@funder_admin, false)
      end

      it 'has admin link', js: true do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target funder', js: true do
        res2 = create(:resource, user: @user)

        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(@res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects and displays funders and awards field by default', js: true do
        visit root_path
        click_button 'Datasets'
        # click_link 'Admin dashboard
        visit stash_url_helpers.admin_dashboard_path
        expect(find('#funders')).to be_checked
        expect(find('#awards')).to be_checked
        expect(find('thead')).to have_text('Grant funders')
        expect(find('#search_results')).to have_text(@contributor.contributor_name, count: 2)
      end
    end
  end
end
