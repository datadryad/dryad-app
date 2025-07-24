RSpec.feature 'CurationActivity', type: :feature do
  include Mocks::Stripe
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Datacite

  context :curating_dataset do

    before(:each) do
      mock_salesforce!
      mock_stripe!
      mock_datacite_gen!
      create(:tenant)
      @user = create(:user, tenant_id: 'ucop')
      @resource = create(:resource, user: @user, identifier: create(:identifier), skip_datacite_update: true)
      create(:curation_activity_no_callbacks, status: 'curation', user_id: @user.id, resource_id: @resource.id)
      @resource.resource_states.first.update(resource_state: 'submitted')
      sign_in(create(:user, role: 'curator'))
      visit("#{stash_url_helpers.admin_dashboard_path}?curation_status=curation")
    end

    it 'renders salesforce links in notes field', js: true do
      @curation_activity = create(:curation_activity, note: 'Not a valid SF link', resource: @resource)
      @curation_activity = create(:curation_activity, note: 'SF #0001 does not exist', resource: @resource)
      @curation_activity = create(:curation_activity, note: 'SF #0002 should exist', resource: @resource)
      within(:css, 'tbody tr', wait: 10) do
        find('a[title="Activity log"]').click
      end
      within(:css, '#activity_log_table tbody:last-child') do
        find('button[aria-label="Curation activity"]').click
      end
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_text('Not a valid SF link')
      # 'SF #0001' is not a valid case number, so the text is not changed
      expect(page).to have_text('SF #0001')
      # 'SF #0002' should be turned into a link with the caseID 'abc',
      # and the '#' dropped to display the normalized form of the case number
      expect(page).to have_link('SF 0002', href: 'https://testsalesforce.com/lightning/r/Case/abc/view')
    end

    it 'renders salesforce section', js: true do
      within(:css, 'tbody tr', wait: 10) do
        find('a[title="Activity log"]').click
      end
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_text('Salesforce cases')
      expect(page).to have_link('SF 0003', href: 'https://dryad.lightning.force.com/lightning/r/Case/abc1/view')
    end
  end

  context :roles do

    before(:each) do
      mock_salesforce!
      mock_solr!
      mock_stripe!
      mock_datacite_gen!
      neuter_curation_callbacks!
      @admin = create(:user)
      create(:role, user: @admin, role: 'admin', role_object: @admin.tenant)
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id)
    end

    context :tenant_admin, js: true do
      it 'allows adding notes to the curation activity log' do
        sign_in(@admin)
        visit stash_url_helpers.admin_dashboard_path

        expect(page).to have_css('a[title="Activity log"]')
        find('a[title="Activity log"]').click

        expect(page).to have_text('This is the dataset activity page.')
        expect(page).to have_text('Add note')
      end
    end

    context :superuser do

      before(:each) do
        mock_salesforce!
        @superuser = create(:user, role: 'superuser')
        sign_in(@superuser, false)
        visit stash_url_helpers.admin_dashboard_path

        expect(page).to have_css('a[title="Activity log"]')
        find('a[title="Activity log"]').click

        expect(page).to have_text('This is the dataset activity page.')
      end

      it 'adds a note to the curation activity log', js: true do
        within(:css, '#activity_log_table tbody:last-child') do
          find('button[aria-label="Curation activity"]').click
        end
        click_button 'Add note'
        fill_in('stash_engine_curation_activity[note]', with: 'This is a test of the note functionality')
        click_button('Submit')
        expect(page).to have_text('This is a test of the note functionality')
      end

      it 'change delete reference date', js: true do
        create(:curation_activity_no_callbacks, status: 'action_required', user_id: @user.id, resource_id: @resource.id)
        visit stash_url_helpers.admin_dashboard_path
        find('a[title="Activity log"]').click
        within(:css, '#activity_log_table tbody:last-child') do
          find('button[aria-label="Curation activity"]').click
        end
        click_button 'Edit notification date'
        fill_in('notification_date', with: Date.today + 2.months)
        fill_in('[curation_activity][note]', with: 'Some Note')
        click_button('Submit')

        expect(page).to have_text("Changed notification start date to #{(Date.today + 1.month).strftime('%b %d, %Y')}.")
        expect(page).to have_text('Some Note')
      end

      it 'allows superuser to set a fee waiver', js: true do
        expect(@resource.identifier.payment_type).to be(nil)
        expect(page).to have_text('Payment:')
        click_button('Apply fee discount')
        expect(page).to have_text('Please provide a reason')
        find("#select_div option[value='no_funds']").select_option
        click_button('Submit')
        expect(@resource.identifier.payment_type).to be(nil)
      end
    end

    context :limited_curator do
      before(:each) do
        create(:role, user: @user, role: 'admin')
        sign_in(@user, false)
      end

      it 'allows adding notes to the curation activity log', js: true do
        visit stash_url_helpers.admin_dashboard_path

        expect(page).to have_css('a[title="Activity log"]')
        find('a[title="Activity log"]').click

        expect(page).to have_text('This is the dataset activity page.')
        expect(page).to have_text('Add note')
      end
    end

    context :journal_admin do
      before(:each) do
        @journal = create(:journal)
        @journal_admin = create(:user)
        @journal_role = create(:role, role_object: @journal, user: @journal_admin)
        @journal_admin.reload
        sign_in(@journal_admin, false)
        ident1 = create(:identifier)
        @res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
        create(:internal_datum, identifier_id: ident1.id, data_type: 'publicationISSN', value: @journal.single_issn)
        create(:internal_datum, identifier_id: ident1.id, data_type: 'publicationName', value: @journal.title)
        create(:resource_publication, resource_id: @res1.id, publication_issn: @journal.single_issn, publication_name: @journal.title)
        ident1.reload
      end

      it 'allows adding notes to the curation activity log', js: true do
        visit stash_url_helpers.admin_dashboard_path

        expect(page).to have_css('a[title="Activity log"]')
        find('a[title="Activity log"]').click

        expect(page).to have_text('This is the dataset activity page.')
        expect(page).to have_text('Add note')
      end
    end

    context :tenant_curator do

      before(:each) do
        mock_salesforce!
        @tenant_curator = create(:user)
        create(:role, user: @tenant_curator, role: 'curator', role_object: @tenant_curator.tenant)
        sign_in(@tenant_curator, false)
      end

      it 'allows adding notes to the curation activity log', js: true do
        visit stash_url_helpers.admin_dashboard_path

        expect(page).to have_css('a[title="Activity log"]')
        find('a[title="Activity log"]').click

        expect(page).to have_text('This is the dataset activity page.')
        expect(page).to have_text('Add note')
      end
    end
  end
end
