require 'pry-remote'

RSpec.feature 'CurationActivity', type: :feature do
  include Mocks::Stripe
  include Mocks::Tenant
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Datacite

  context :curating_dataset do

    before(:each) do
      mock_salesforce!
      mock_stripe!
      mock_datacite_gen!
      @user = create(:user, tenant_id: 'ucop')
      @resource = create(:resource, user: @user, identifier: create(:identifier), skip_datacite_update: true)
      create(:curation_activity_no_callbacks, status: 'curation', user_id: @user.id, resource_id: @resource.id)
      @resource.resource_states.first.update(resource_state: 'submitted')
      sign_in(create(:user, role: 'curator', tenant_id: 'dryad'))
      visit("#{stash_url_helpers.ds_admin_path}?curation_status=curation")
    end

    it 'renders salesforce links in notes field' do
      @curation_activity = create(:curation_activity, note: 'Not a valid SF link', resource: @resource)
      @curation_activity = create(:curation_activity, note: 'SF #0001 does not exist', resource: @resource)
      @curation_activity = create(:curation_activity, note: 'SF #0002 should exist', resource: @resource)
      within(:css, '.c-lined-table__row', wait: 10) do
        find('button[title="View Activity Log"]').click
      end
      expect(page).to have_text('Activity log for')
      expect(page).to have_text('Not a valid SF link')
      # 'SF #0001' is not a valid case number, so the text is not changed
      expect(page).to have_text('SF #0001')
      # 'SF #0002' should be turned into a link with the caseID 'abc',
      # and the '#' dropped to display the normalized form of the case number
      expect(page).to have_link('SF 0002', href: 'https://testsalesforce.com/lightning/r/Case/abc/view')
    end

    it 'renders salesforce section' do
      within(:css, '.c-lined-table__row', wait: 10) do
        find('button[title="View Activity Log"]').click
      end
      expect(page).to have_text('Activity log for')
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
      mock_tenant!
      neuter_curation_callbacks!
      @admin = create(:user, role: 'admin', tenant_id: 'mock_tenant')
      @user = create(:user, tenant_id: @admin.tenant_id)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id)
    end

    context :tenant_admin do
      it 'allows adding notes to the curation activity log' do
        sign_in(@admin)
        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(page).to have_text('Activity log for')
        expect(page).to have_text('Add note')
      end
    end

    context :superuser do

      before(:each) do
        mock_salesforce!
        @superuser = create(:user, role: 'superuser', tenant_id: 'dryad')
        sign_in(@superuser, false)
      end

      it 'allows adding notes to the curation activity log' do
        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(page).to have_text('Activity log for')
        expect(page).to have_text('Add note')
      end

      it 'adds a note to the curation activity log', js: true do
        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(page).to have_text('Activity log for')
        click_button 'Add note'
        fill_in('stash_engine_curation_activity[note]', with: 'This is a test of the note functionality')
        click_button('Submit')
        expect(page).to have_text('This is a test of the note functionality')
      end

      it 'adds internal data', js: true do
        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(page).to have_text('Activity log for')
        click_button 'Add data'
        select('pubmedID', from: 'stash_engine_internal_datum[data_type]')
        fill_in('stash_engine_internal_datum[value]', with: '123456')
        click_button('Submit')
        expect(page).to have_text('pubmedID')
      end

      it 'allows superuser to set a fee waiver', js: true do
        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(@resource.identifier.payment_type).to be(nil)
        expect(page).to have_text('Payment information')
        click_button('Apply fee waiver')
        expect(page).to have_text('Please provide a reason')
        find("#select_div option[value='no_funds']").select_option
        click_button('Submit')
        expect(@resource.identifier.payment_type).to be(nil), wait: 2
      end

      before(:each) do
        mock_stripe!
        mock_solr!
        mock_repository!
        mock_datacite_gen!
        mock_salesforce!

        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(page).to have_text('Payment information')
        expect { click_button('Apply fee waiver') }.to raise_error(Capybara::ElementNotFound)
      end
    end

    context :limited_curator do

      before(:each) do
        mock_aws!
        mock_salesforce!
        mock_stripe!
        mock_repository!
        mock_datacite_gen!
        @user = create(:user, tenant_id: 'ucop')
        @resource = create(:resource, user: @user, identifier: create(:identifier), skip_datacite_update: true)
        create(:curation_activity_no_callbacks, status: 'curation', user_id: @user.id, resource_id: @resource.id)
        @resource.resource_states.first.update(resource_state: 'submitted')
        sign_in(create(:user, role: 'superuser', tenant_id: 'ucop'))
        visit "#{dashboard_path}?curation_status=curation"
      end

      it 'allows adding notes to the curation activity log' do
        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(page).to have_text('Activity log for')
        expect(page).to have_text('Add note')
      end
    end

    context :journal_admin do
      before(:each) do
        @journal = create(:journal)
        @journal_admin = create(:user, tenant_id: 'mock_tenant')
        @journal_role = create(:journal_role, journal: @journal, user: @journal_admin, role: 'admin')
        @journal_admin.reload
        sign_in(@journal_admin, false)
        ident1 = create(:identifier)
        @res1 = create(:resource, identifier_id: ident1.id, user: @user, tenant_id: @admin.tenant_id)
        StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationISSN', value: @journal.single_issn)
        StashEngine::InternalDatum.create(identifier_id: ident1.id, data_type: 'publicationName', value: @journal.title)
        ident1.reload
      end

      it 'allows adding notes to the curation activity log' do
        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(page).to have_text('Activity log for')
        expect(page).to have_text('Add note')
      end
    end

    context :tenant_curator do

      before(:each) do
        mock_salesforce!
        @tenant_curator = create(:user, role: 'tenant_curator', tenant_id: 'mock_tenant')
        sign_in(@tenant_curator, false)
      end

      it 'allows adding notes to the curation activity log' do
        visit stash_url_helpers.ds_admin_path

        expect(page).to have_css('button[title="View Activity Log"]')
        find('button[title="View Activity Log"]').click

        expect(page).to have_text('Activity log for')
        expect(page).to have_text('Add note')
      end
    end
  end
end
