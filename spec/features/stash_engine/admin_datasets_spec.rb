require 'pry-remote'

RSpec.feature 'AdminDatasets', type: :feature do
  include DatasetHelper
  include Mocks::Aws
  include Mocks::Repository
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::DataFile

  context :content do

    before(:each) do
      mock_stripe!
      mock_salesforce!
      Timecop.travel(Time.now.utc - 1.hour)
      # Create a user, identifier and 2 resources for each tenant
      %w[ucop dryad mock_tenant].each do |tenant|
        user = create(:user, tenant_id: tenant)
        @identifiers = []
        2.times.each do
          identifier = create(:identifier)
          create(:resource, :submitted, user: user, identifier: identifier)
          cite_number = rand(4)
          cite_number.times { create(:counter_citation, identifier: identifier) }
          create(:counter_stat, citation_count: cite_number, identifier: identifier)
          @identifiers.push(identifier)
        end
      end
      Timecop.return
    end

    it 'shows admins datasets for their tenant' do
      sign_in(create(:user, role: 'admin', role_object: StashEngine::Tenant.find('ucop'), tenant_id: 'ucop'))
      visit stash_url_helpers.ds_admin_path
      expect(all('.c-lined-table__row').length).to eql(2)
    end

    it 'shows consortium admins datasets for their tenants' do
      consortium = create(:tenant, id: 'consortium')
      create(:tenant, id: 'member1', sponsor_id: 'consortium')
      create(:tenant, id: 'member2', sponsor_id: 'consortium')
      user = create(:user, tenant_id: 'member1')
      2.times do
        identifier = create(:identifier)
        create(:resource, :submitted, user: user, identifier: identifier)
      end
      sign_in(create(:user, role: 'admin', role_object: consortium, tenant_id: 'consortium'))
      visit stash_url_helpers.ds_admin_path
      expect(page).to have_select('tenant')
      expect(page).to have_selector('#tenant option', count: 4)
      expect(all('.c-lined-table__row').length).to eql(2)
    end

    it 'lets curators see all datasets' do
      sign_in(create(:user, role: 'curator'))
      visit stash_url_helpers.ds_admin_path
      expect(all('.c-lined-table__row').length).to eql(6)
    end

    it 'has ajax showing counter stats and citations', js: true do
      sign_in(create(:user, role: 'curator'))
      visit stash_url_helpers.ds_admin_path
      el = find('td', text: @identifiers.first.resources.first.title)
      el = el.find(:css, '.js-stats')
      el.click
      my_stats = @identifiers.first.counter_stat
      page.first :css, '.o-metrics__icon'
      expect(page).to have_content("#{my_stats.citation_count} citations")
      expect(page).to have_content("#{my_stats.views} views")
      expect(page).to have_content("#{my_stats.downloads} downloads")
    end

    it 'generates a csv having dataset information with citations, views and downloads' do
      sign_in(create(:user, role: 'curator'))
      visit stash_url_helpers.ds_admin_path
      click_link('Get Comma Separated Values (CSV) for import into Excel')

      title = @identifiers.first.resources.first.title
      my_stats = @identifiers.first.counter_stat

      csv_line = page.body.split("\n").select { |i| i.start_with?(title) }.first

      # NOTE: this doesn't split "correctly", since some entries contain embedded commas,
      # but it doesn't matter as long as it is synced with the index below
      csv_parts = csv_line.split(',')

      expect(csv_parts[-5].to_i).to eql(my_stats.views)
      expect(csv_parts[-4].to_i).to eql(my_stats.downloads)
      expect(csv_parts[-3].to_i).to eql(my_stats.citation_count)
    end

    it 'generates a csv that includes submitter institutional name' do
      sign_in(create(:user, role: 'curator'))
      visit stash_url_helpers.ds_admin_path
      click_link('Get Comma Separated Values (CSV) for import into Excel')

      title = @identifiers.first.resources.first.title

      csv_line = page.body.split("\n").select { |i| i.start_with?(title) }.first

      # NOTE: this doesn't split "correctly", since some entries contain embedded commas,
      # but it doesn't matter as long as it is synced with the index below
      csv_parts = csv_line.split(',')

      expect(csv_parts[-2]).to eql(@identifiers.first.resources.first.tenant.long_name)
    end
  end

  context :roles do
    before(:each) do
      mock_aws!
      mock_solr!
      mock_salesforce!
      mock_stripe!
      mock_repository!
      mock_datacite!
      mock_file_content!
      neuter_curation_callbacks!
      Timecop.travel(Time.now.utc - 1.minute)
      create(:tenant)
      @admin = create(:user, tenant_id: 'test_tenant')
      create(:role, user: @admin, role_object: @admin.tenant)
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id, skip_datacite_update: true)
      Timecop.return
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
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(res1.title)
        expect(page).not_to have_text(res2.title)
      end

      it 'Limits options in the curation page', js: true do
        visit root_path
        click_button 'Datasets'
        click_link 'Admin dashboard'
        click_on('Reset all filters')

        expect(page).to have_content(@resource.title)
        expect(page).not_to have_selector('button.c-admin-edit-icon .fa-pencil') # no pencil editing icons for you
      end

      it 'does not allow editing a dataset from the curation page', js: true do
        visit root_path
        click_button 'Datasets'
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).not_to have_css('button[title="Edit dataset"]')
      end
    end

    context :curator, js: true do

      before(:each) do
        create(:curation_activity_no_callbacks, status: 'curation', user_id: @user.id, resource_id: @resource.id)
        @resource.resource_states.first.update(resource_state: 'submitted')
        sign_in(create(:user, role: 'curator'))
        visit stash_url_helpers.ds_admin_path(curation_status: 'curation')
      end

      it 'has admin link', js: true do
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'submits a curation status changes and reflects in the page and history afterwards' do
        within(:css, '.c-lined-table__row', wait: 10) do
          find('button[title="Update status"]').click
        end
        # select the author action required

        find("#activity_status_select option[value='action_required']").select_option

        # fill in a note
        fill_in(id: 'activity_note', with: 'My cat says hi')
        click_button('Submit')

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text('Action required')
          find('a[title="Activity log"]').click
        end

        expect(page).to have_text('My cat says hi')
      end

      it 'allows curation editing of users dataset and returning to admin list in same state afterward' do
        # the button to edit has this class on it
        find('.js-trap-curator-url').click
        all('[id^=instit_affil_]').last.set('test institution')
        page.send_keys(:tab)
        page.has_css?('.use-text-entered')
        all(:css, '.use-text-entered').each { |i| i.set(true) }
        fill_in_keywords
        navigate_to_readme
        add_required_data_files
        navigate_to_review
        agree_to_everything
        fill_in 'user_comment', with: Faker::Lorem.sentence
        submit = find_button('submit_dataset', disabled: :all)
        submit.click
        expect(URI.parse(current_url).request_uri).to eq("#{stash_url_helpers.ds_admin_path}?curation_status=curation")
      end

      it 'allows curation editing and aborting editing of user dataset and return to list in same state afterward' do
        # the button to edit has this class on it
        find('.js-trap-curator-url').click

        expect(page).to have_field('Dataset title') # so it waits for actual ajax doc to load before doing anything else

        click_on('Cancel and Discard Changes')
        find('#railsConfirmDialogYes').click
        expect(URI.parse(current_url).request_uri).to eq("#{stash_url_helpers.ds_admin_path}?curation_status=curation")
      end
    end

    context :superuser, js: true do

      before(:each) do
        mock_salesforce!
        @superuser = create(:user, role: 'superuser')
        sign_in(@superuser, false)
      end

      it 'has admin link' do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
        expect(page).to have_link('Publication updater')
        expect(page).to have_link('Status dashboard')
        expect(page).to have_link('Submission queue')
      end

      it 'allows editing a dataset' do
        Timecop.travel(Time.now.utc - 2.minutes)
        @user = create(:user, tenant_id: @admin.tenant_id)
        @identifier = create(:identifier)
        expect { @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id) }
          .to change(StashEngine::Resource, :count).by(1)
        expect { @resource.subjects << [create(:subject), create(:subject), create(:subject)] }
          .to change(StashDatacite::Subject, :count).by(3)
        Timecop.return
        visit stash_url_helpers.user_admin_profile_path(@user)
        expect(page).to have_css('button[title="Edit dataset"]')
        find('button[title="Edit dataset"]').click
        expect(page).to have_text("You are editing #{@user.name}'s dataset.")
        all('[id^=instit_affil_]').last.set('test institution')
        page.send_keys(:tab)
        page.has_css?('.use-text-entered')
        all(:css, '.use-text-entered').each { |i| i.set(true) }
        add_required_data_files
        mock_file_content!
        click_link 'Review and submit'
        agree_to_everything
        expect(page).to have_css('input#user_comment')
      end

      it 'allows assigning a curator to a dataset' do
        expect { @curator = create(:user, role: 'superuser', tenant_id: 'dryad') }.to change(StashEngine::User, :count).by(1)

        visit stash_url_helpers.ds_admin_path

        expect(page).to have_text('Admin dashboard')
        expect(page).to have_css('button[title="Update curator"]')
        find('button[title="Update curator"]').click
        find("#current_editor option[value='#{@curator.id}']").select_option
        click_button('Submit')

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text(@curator.name.to_s)
        end

      end

      it 'allows un-assigning a curator, keeping status if it is peer_review' do
        @curator = create(:user, role: 'superuser', tenant_id: 'dryad')
        expect { create(:curation_activity, resource: @resource, status: 'peer_review', note: 'forcing to peer_review') }
          .to change(StashEngine::CurationActivity, :count).by(1)
        @resource.reload

        visit stash_url_helpers.ds_admin_path

        expect(page).to have_text('Admin dashboard')
        expect(page).to have_css('button[title="Update curator"]')
        find('button[title="Update curator"]').click
        find("#current_editor option[value='#{@curator.id}']").select_option
        click_button('Submit')
        find('button[title="Update curator"]').click
        find("#current_editor option[value='0']").select_option
        click_button('Submit')
        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).not_to have_text(@curator.name_last_first)
        end
        @resource.reload

        expect(@resource.current_editor_id).to eq(nil)
        expect(@resource.current_curation_status).to eq('peer_review')
      end

      it 'allows un-assigning a curator, changing status if it is curation' do
        @curator = create(:user, role: 'superuser')
        expect { create(:curation_activity, resource: @resource, status: 'curation', note: 'forcing to curation') }
          .to change(StashEngine::CurationActivity, :count).by(1)
        @resource.reload

        visit stash_url_helpers.ds_admin_path

        expect(page).to have_text('Admin dashboard')
        expect(page).to have_css('button[title="Update curator"]')

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text('Curation')
        end

        find('button[title="Update curator"]').click
        find("#current_editor option[value='#{@curator.id}']").select_option
        click_button('Submit')
        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text(@curator.name)
        end
        find('button[title="Update curator"]').click
        find("#current_editor option[value='0']").select_option
        click_button('Submit')
        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).not_to have_text(@curator.name)
        end
        @resource.reload

        within(:css, '.c-lined-table__row', wait: 10) do
          expect(page).to have_text('Submitted')
        end
      end
    end

    context :app_admin, js: true do

      before(:each) do
        create(:role, user: @user, role: 'admin')
        sign_in(@user, false)
      end

      it 'shows limited menus to an administrative curator' do
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
        expect(page).to have_link('Curation stats')
        expect(page).to have_link('Journals')
        expect(page).not_to have_link('User management')
        expect(page).not_to have_link('Submission queue')
      end

      it 'Limits options in the curation page' do
        visit root_path
        click_button 'Datasets'
        click_link 'Admin dashboard'
        click_on('Reset all filters')

        expect(page).to have_content(@resource.title)
        expect(page).not_to have_selector('button.c-admin-edit-icon .fa-pencil') # no pencil editing icons for you
      end
    end

    context :tenant_curator, js: true do

      before(:each) do
        mock_salesforce!
        @tenant_curator = create(:user, role: 'curator', role_object: @admin.tenant, tenant_id: @admin.tenant_id)
        sign_in(@tenant_curator, false)
      end

      it 'has admin link' do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target institution' do
        ident1 = create(:identifier)
        res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @tenant_curator.tenant_id)
        ident2 = create(:identifier)
        user2 = create(:user, tenant_id: 'bad_tenant')
        res2 = create(:resource, identifier_id: ident2.id, user: user2, tenant_id: user2.tenant_id)

        visit root_path
        click_button 'Datasets'
        click_link 'Admin dashboard'
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(res1.title)
        expect(page).not_to have_text(res2.title)
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
        create(:internal_datum, identifier_id: ident1.id, data_type: 'publicationISSN', value: @journal.single_issn)
        create(:internal_datum, identifier_id: ident1.id, data_type: 'publicationName', value: @journal.title)
        ident1.reload
      end

      it 'has admin link' do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target journal' do
        ident2 = create(:identifier)
        res2 = create(:resource, identifier_id: ident2.id, user: @user, tenant_id: @admin.tenant_id)

        visit root_path
        click_button 'Datasets'
        find('a', exact_text: 'Admin dashboard').click
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(@res1.title)
        expect(page).not_to have_text(res2.title)
      end
    end

    context :funder_admin, js: true do

      before(:each) do
        ident1 = create(:identifier)
        @res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
        contributor = create(:contributor, resource: @res1)
        funder = create(:funder, name: contributor.contributor_name, ror_id: contributor.name_identifier_id)
        @funder_admin = create(:user, tenant_id: 'mock_tenant')
        @funder_role = create(:role, role_object: funder, user: @funder_admin)
        @funder_role.reload
        @funder_admin.reload
        sign_in(@funder_admin, false)
      end

      it 'has admin link' do
        visit root_path
        click_button 'Datasets'
        expect(page).to have_link('Admin dashboard')
      end

      it 'only shows datasets from the target journal' do
        ident2 = create(:identifier)
        res2 = create(:resource, identifier_id: ident2.id, user: @user, tenant_id: @admin.tenant_id)

        visit root_path
        click_button 'Datasets'
        find('a', exact_text: 'Admin dashboard').click
        expect(page).to have_text('Admin dashboard')
        expect(page).to have_text(@res1.title)
        expect(page).not_to have_text(res2.title)
      end
    end
  end
end
