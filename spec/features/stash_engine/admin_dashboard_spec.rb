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
      2.times do
        identifier = create(:identifier)
        @resource = create(:resource, :submitted, publication_date: nil, user: @user, identifier: identifier)
      end
      sign_in(@superuser, false)
    end

    it 'has admin links for superuser', js: true do
      visit root_path
      find_button('Datasets').hover
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
      check 'affiliations'
      check 'countries'
      check 'funders'
      check 'dpc'
      click_button('Apply')
      # must visit instead of clicking link; adding js: true breaks ability to load CSV
      visit stash_url_helpers.admin_dashboard_results_path(format: :csv)
      csv_line = page.body.split("\n").first
      csv_parts = csv_line.split(',')
      expect(csv_parts).to include('Submitter', 'Metrics', 'Grant funders')
    end

    it 'has 2 search fields', js: true do
      visit stash_url_helpers.admin_dashboard_path
      expect(page).to have_text('Admin dashboard')
      expect(page).to have_field('search-string')
      expect(page).to have_field('related-search')
    end

    context :date_and_state_filters do
      before(:each) do
        create(:curation_activity, status: 'curation', user: @superuser, resource: @resource)
        2.times do
          identifier = create(:identifier)
          create(:resource, publication_date: nil, user: @user, identifier: identifier)
        end
        3.times do
          Timecop.travel(Time.now.utc.to_date - 2.days)
          identifier = create(:identifier)
          create(:resource_published, user: @user, identifier: identifier)
          Timecop.return
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
        assert_selector('tbody tr', count: 10)
        click_button('multiselect-status__input')
        check 'status-in_progress'
        click_button('Apply')
        assert_selector('tbody tr', count: 2)
        click_button('multiselect-status__input')
        check 'status-submitted'
        click_button('Apply')
        assert_selector('tbody tr', count: 3)
        click_button('multiselect-status__input')
        check 'status-curation'
        click_button('Apply')
        assert_selector('tbody tr', count: 4)
        click_button('multiselect-status__input')
        check 'status-published'
        click_button('Apply')
        assert_selector('tbody tr', count: 7)
        click_button('multiselect-status__input')
        check 'status-embargoed'
        click_button('Apply')
        assert_selector('tbody tr', count: 10)
      end

      it 'filters on submitted date', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        fill_in('submit_datestart', with: Time.now.utc.to_date)
        click_button('Apply')
        assert_selector('tbody tr', count: 8)
      end

      it 'filters on first submitted date', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        fill_in('first_sub_datestart', with: (Time.now.utc.to_date - 2.days))
        click_button('Apply')
        assert_selector('tbody tr', count: 8)
        fill_in('first_sub_dateend', with: (Time.now.utc.to_date - 1.day))
        click_button('Apply')
        assert_selector('tbody tr', count: 3)
      end

      it 'filters on published date', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        fill_in('publication_datestart', with: Time.now.utc.to_date)
        click_button('Apply')
        assert_selector('tbody tr', count: 6)
        fill_in('publication_dateend', with: Time.now.utc.to_date)
        click_button('Apply')
        assert_selector('tbody tr', count: 3)
      end

      it 'filters on first published date', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        fill_in('first_pub_datestart', with: (Time.now.utc.to_date - 2.days))
        click_button('Apply')
        assert_selector('tbody tr', count: 6)
        fill_in('first_pub_dateend', with: Time.now.utc.to_date)
        click_button('Apply')
        assert_selector('tbody tr', count: 3)
      end
    end
  end

  context :roles do
    before(:each) do
      Timecop.travel(Time.now.utc - 1.minute)
      create(:tenant)
      @admin = create(:user, tenant_id: 'test_tenant')
      create(:role, user: @admin, role_object: @admin.tenant)
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id, skip_datacite_update: true)
      Timecop.return
    end

    context :app_admin, js: true do
      before(:each) do
        create(:role, user: @user, role: 'admin')
        sign_in(@user, false)
      end

      it 'shows limited menus to an administrative curator', js: true do
        visit root_path
        find_button('Datasets').hover
        expect(page).to have_link('Admin dashboard')
        expect(page).to have_link('Curation stats')
        expect(page).to have_link('Journals')
        expect(page).not_to have_link('User management')
        expect(page).not_to have_link('Submission queue')
      end

      it 'has all filters for system users', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_select('filter-member')
        expect(page).to have_button('multiselect-status__input')
        expect(page).to have_select('filter-curator')
        expect(page).to have_field('searchselect-journal__input')
        expect(page).to have_select('filter-sponsor')
        expect(page).to have_field('searchselect-funder__input')
        expect(page).to have_field('searchselect-affiliation__input')
        expect(page).to have_field('submit_datestart')
        expect(page).to have_field('first_sub_datestart')
        expect(page).to have_field('publication_datestart')
        expect(page).to have_field('first_pub_datestart')
      end

      it 'limits options in the dashboard', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_content(@resource.title)
        expect(page).not_to have_selector('button.c-admin-edit-icon .fa-pencil') # no pencil editing icons for you
      end
    end

    context :curator, js: true do
      before(:each) do
        @curator = create(:user, role: 'curator')
        sign_in(@curator)
      end

      it 'has admin link', js: true do
        visit root_path
        find_button('Datasets').hover
        expect(page).to have_link('Admin dashboard')
        expect(page).to have_link('Publication updater')
      end

      it 'selects identifiers and curator fields by default', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(find('#identifiers')).to be_checked
        expect(find('thead')).to have_text('Publication IDs')
        expect(find('#curator')).to be_checked
        expect(find('thead')).to have_text('Curator')
      end

      context :actions, js: true do
        before(:each) do
          visit root_path
          find_button('Datasets').hover
          click_link 'Admin dashboard'
        end

        it 'allows assigning a curator to a dataset' do
          click_button 'Update curator'
          select(@curator.name_last_first, from: '_curator_id')
          click_button('Submit')
          expect(find('#search_results')).to have_text(@curator.name, count: 1)
        end

        it 'allows un-assigning a curator, keeping status if it is peer_review' do
          create(:curation_activity, status: 'peer_review', resource_id: @resource.id, user: @resource.submitter)
          visit stash_url_helpers.admin_dashboard_path
          expect(page).to have_text('Admin dashboard')
          click_button 'Update curator'
          select(@curator.name_last_first, from: '_curator_id')
          click_button('Submit')
          expect(find('#search_results')).to have_text(@curator.name, count: 1)
          click_button 'Update curator'
          select('unassign', from: '_curator_id')
          click_button('Submit')
          expect(find('#search_results')).not_to have_text(@curator.name)
          @resource.reload
          expect(@resource.user_id).to eq(nil)
          expect(@resource.current_curation_status).to eq('peer_review')
        end

        context :in_curation do
          before(:each) do
            create(:curation_activity, status: 'curation', user_id: @curator.id, resource_id: @resource.id)
            @resource.update(user_id: @curator.id, accepted_agreement: true)
            @resource.identifier.update(last_invoiced_file_size: @resource.total_file_size)
            visit stash_url_helpers.admin_dashboard_path
          end

          it 'filters by curator', js: true do
            create(:resource, :submitted, user: @user, tenant_id: @admin.tenant_id, skip_datacite_update: true)
            visit stash_url_helpers.admin_dashboard_path
            expect(page).to have_text('Admin dashboard')
            assert_selector('tbody tr', count: 2)
            select(@curator.name_last_first, from: 'filter-curator')
            click_button('Apply')
            assert_selector('tbody tr', count: 1)
            expect(find('#search_results')).to have_text(@curator.name, count: 1)
          end

          it 'allows un-assigning a curator, changing status if it is curation' do
            expect(page).to have_text('Admin dashboard')
            expect(find('#search_results')).to have_text('Curation')
            expect(find('#search_results')).to have_text(@curator.name, count: 1)
            click_button 'Update curator'
            select('unassign', from: '_curator_id')
            click_button('Submit')
            expect(find('#search_results')).not_to have_text(@curator.name)
            expect(find('#search_results')).to have_text('Submitted')
            @resource.reload
            expect(@resource.user_id).to eq(nil)
            expect(@resource.current_curation_status).to eq('submitted')
          end

          it 'submits a curation status change and reflects in the page and history afterwards' do
            within(:css, 'tbody tr') do
              click_button 'Update status'
            end
            find("#_curation_activity_status option[value='action_required']").select_option
            fill_in(id: '_curation_activity_note', with: 'My cat says hi')
            click_button('Submit')
            expect(find('tbody tr')).to have_text('Action required')
            within(:css, 'tbody tr') do
              click_link 'Activity log'
            end
            within(:css, '#activity_log_table tbody:last-child') do
              find('button[aria-label="Curation activity"]').click
            end
            expect(page).to have_text('My cat says hi')
          end

          it 'allows curation editing of users dataset and returning to admin list in same state afterward' do
            create(:description, resource: @resource, description_type: 'technicalinfo')
            create(:description, resource: @resource, description_type: 'hsi_statement', description: nil)
            create(:data_file, resource: @resource)
            @resource.reload
            @resource.identifier.update(last_invoiced_file_size: @resource.total_file_size)
            click_button 'Edit dataset'
            click_button 'Authors'
            all('[id^=instit_affil_]').last.set('test institution')
            page.send_keys(:tab)
            page.has_css?('.use-text-entered')
            all(:css, '.use-text-entered').each { |i| i.set(true) }
            click_button 'Preview changes'
            click_button 'Subjects'
            fill_in_keywords
            refresh
            fill_in 'user_comment', with: Faker::Lorem.sentence
            submit_form
            expect(page).to have_text('Admin dashboard')
            expect(page).to have_text('Submitted updates for doi:')
          end

          it 'allows aborting curation editing of user dataset and return to list in same state afterward' do
            click_button 'Edit dataset'
            expect(page).to have_text('Dataset submission')
            click_on('Cancel and Discard Changes')
            find('#railsConfirmDialogYes').click
            expect(page).to have_text('Admin dashboard')
            expect(page).to have_text('The in-progress version was successfully deleted')
          end
        end

      end
    end

    context :tenant_curator, js: true do
      before(:each) do
        @tenant_curator = create(:user, role: 'curator', role_object: @admin.tenant, tenant_id: @admin.tenant_id)
        sign_in(@tenant_curator, false)
      end

      it 'has admin link', js: true do
        visit root_path
        find_button('Datasets').hover
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target institution', js: true do
        ident1 = create(:identifier)
        res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @tenant_curator.tenant_id)
        ident2 = create(:identifier)
        user2 = create(:user, tenant_id: 'bad_tenant')
        res2 = create(:resource, identifier_id: ident2.id, user: user2, tenant_id: user2.tenant_id)

        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects affiliations field by default', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(find('#affiliations')).to be_checked
      end
    end

    context :tenant_admin do
      before(:each) do
        sign_in(@admin)
      end

      it 'has admin link', js: true do
        visit root_path
        find_button('Datasets').hover
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target institution', js: true do
        ident1 = create(:identifier)
        res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
        ident2 = create(:identifier)
        user2 = create(:user, tenant_id: 'bad_tenant')
        res2 = create(:resource, identifier_id: ident2.id, user: user2, tenant_id: user2.tenant_id)

        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects affiliations field by default', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(find('#affiliations')).to be_checked
      end

      it 'Limits options in the dashboard', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_content(@resource.title)
        expect(page).not_to have_selector('button.c-admin-edit-icon .fa-pencil') # no pencil editing icons for you
      end

      it 'does not allow editing a dataset from the dashboard', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
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
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        assert_selector('tbody tr', count: 4)
        expect(page).to have_text(@res2.title)
        expect(page).not_to have_text(@res1.title)
      end

      it 'shows consortium admins dropdown for their tenants', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_select('filter-member')
        expect(page).to have_selector('#filter-member option', count: 4)
      end

      it 'filters by tenant', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
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
        create(:resource_publication, publication_issn: @journal.single_issn, publication_name: @journal.title, resource_id: @res1.id)
        @res1.reload
      end

      it 'has admin link', js: true do
        visit root_path
        find_button('Datasets').hover
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target journal', js: true do
        ident2 = create(:identifier)
        res2 = create(:resource, identifier_id: ident2.id, user: @user, tenant_id: @admin.tenant_id)

        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(@res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects identifiers field by default', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
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
            create(:resource_publication, publication_issn: @journal.single_issn, publication_name: @journal.title, resource_id: @res1.id)
            @res1.reload
          end
        end
        sign_in(@sponsor_admin, false)
      end

      it 'has admin link', js: true do
        visit root_path
        find_button('Datasets').hover
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target journals', js: true do
        ident2 = create(:identifier)
        res2 = create(:resource, identifier_id: ident2.id, user: @user, tenant_id: @admin.tenant_id)

        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        assert_selector('tbody tr', count: 6)
        expect(page).to have_text(@res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects journal field by default', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(find('#journal')).to be_checked
        expect(find('thead')).to have_text('Journal')
      end

      it 'shows sponsor admins dropdown for their journals', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_select('filter-journal')
        expect(page).to have_selector('#filter-journal option', count: 4)
      end

      it 'filters by journal', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        select(@journal.title, from: 'filter-journal')
        click_button('Apply')
        assert_selector('tbody tr', count: 2)
        expect(find('#search_results')).to have_text(@journal.title, count: 2)
      end

      it 'filters by sponsor', js: true do
        2.times.map { create(:journal_organization) }
        sign_out
        sign_in(create(:user, role: 'superuser'))
        expect(page).to have_text('Admin dashboard')
        assert_selector('tbody tr', count: 7)
        select(@org.name, from: 'filter-sponsor')
        click_button('Apply')
        assert_selector('tbody tr', count: 6)
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
        find_button('Datasets').hover
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target funder', js: true do
        res2 = create(:resource, user: @user)

        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(@res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'selects and displays funders and awards field by default', js: true do
        visit root_path
        find_button('Datasets').hover
        click_link 'Admin dashboard'
        expect(find('#funders')).to be_checked
        expect(find('#awards')).to be_checked
        expect(find('thead')).to have_text('Grant funders')
        expect(find('#search_results')).to have_text(@contributor.contributor_name, count: 2)
      end
    end
  end
end
