RSpec.feature 'AdminDatasets', type: :feature, js: true do
  include Mocks::Stripe
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Github
  include Mocks::Datacite

  context :curating_dataset do

    before(:each) do
      mock_salesforce!
      mock_github!
      mock_stripe!
      mock_datacite_gen!
      create(:tenant)
      @user = create(:user, tenant_id: 'ucop')
      @resource = create(:resource, user: @user, identifier: create(:identifier), skip_datacite_update: true)
      CurationService.new(status: 'curation', resource: @resource, user_id: @user.id).process
      @resource.resource_states.first.update(resource_state: 'submitted')
      @resource.identifier.update(issues: [1234])
      sign_in(create(:user, role: 'curator'))
      visit("#{stash_url_helpers.admin_dashboard_path}?curation_status=curation")
    end

    it 'shows accurate publication status' do
      manuscript = create(:manuscript, identifier: @resource.identifier, status: 'accepted')
      create(:resource_publication, resource: @resource, manuscript_number: manuscript.manuscript_number)
      find('a[title="Activity log"]').click
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_text(manuscript.manuscript_number)
      expect(page).to have_text('accepted')
      create(:related_identifier, resource: @resource, work_type: 'primary_article')
      visit current_path
      expect(page).to have_text('1 related work')
      expect(page).to have_text('published')
    end

    it 'renders salesforce links in notes field' do
      CurationService.new(status: 'in_progress', resource: @resource, note: 'Not a valid SF link').process
      CurationService.new(status: 'in_progress', resource: @resource, note: 'SF #0001 does not exist').process
      CurationService.new(status: 'in_progress', resource: @resource, note: 'SF #0002 should exist').process

      find('a[title="Activity log"]').click
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

    it 'renders salesforce section' do
      find('a[title="Activity log"]').click
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_text('Salesforce cases')
      expect(page).to have_link('SF 0003', href: 'https://dryad.lightning.force.com/lightning/r/Case/abc1/view')
    end

    it 'renders github section' do
      find('a[title="Activity log"]').click
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_text('Github issues')
      expect(page).to have_link('Test github issue', href: 'https://github.com/datadryad/dryad-product-roadmap/issues/1234')
    end

    it 'allows proper at a glance editing' do
      find('a[title="Activity log"]').click
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_button('Edit Flag')
      expect(page).to have_button('Update status')
      expect(page).to have_button('Logout current editor')
      expect(page).to have_button('Edit pub dates')
      expect(page).to have_button('Edit related works')
      expect(page).to have_button('Edit funders')
      expect(page).to have_button('View payment history')
      expect(page).not_to have_button('Edit submitter')
      expect(page).not_to have_button('Apply fee discount')
    end

    it 'allows adding notes to the curation activity log' do
      find('a[title="Activity log"]').click
      expect(page).to have_text('This is the dataset activity page.')
      expect(page).to have_button('Add note')
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
      @resource = create(:resource, :submitted, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id, created_at: 1.minute.ago)
    end

    context :tenant_admin do
      before(:each) do
        sign_in(@admin)
        visit stash_url_helpers.admin_dashboard_path
        find('a[title="Activity log"]').click
        expect(page).to have_text('This is the dataset activity page.')
      end

      it 'allows adding notes to the curation activity log' do
        expect(page).to have_button('Add note')
      end

      it 'does not allow at a glance editing' do
        expect(page).not_to have_button('Edit Flag')
        expect(page).not_to have_button('Update status')
        expect(page).not_to have_button('Logout current editor')
        expect(page).not_to have_button('Edit pub dates')
        expect(page).not_to have_button('Edit related works')
        expect(page).not_to have_button('Edit funders')
        expect(page).not_to have_button('Edit submitter')
        expect(page).not_to have_button('Apply fee discount')
        expect(page).not_to have_button('View payment history')
      end
    end

    context :manager do
      before(:each) do
        mock_github!
        mock_salesforce!
        @manager = create(:user, role: 'manager')
        sign_in(@manager, false)
        visit stash_url_helpers.admin_dashboard_path
        find('a[title="Activity log"]').click
        expect(page).to have_text('This is the dataset activity page.')
      end

      it 'allows editing all at a glance sections' do
        expect(page).to have_button('Edit Flag')
        expect(page).to have_button('Update status')
        expect(page).to have_button('Logout current editor')
        expect(page).to have_button('Edit pub dates')
        expect(page).to have_button('Edit related works')
        expect(page).to have_button('Edit funders')
        expect(page).to have_button('Edit submitter')
        expect(page).to have_button('View payment history')
        expect(page).to have_button('Apply fee discount')
      end

      it 'adds a note to the curation activity log' do
        within(:css, '#activity_log_table tbody:last-child') do
          find('button[aria-label="Curation activity"]').click
        end
        click_button 'Add note'
        fill_in('stash_engine_curation_activity[note]', with: 'This is a test of the note functionality')
        click_button('Submit')
        expect(page).to have_text('This is a test of the note functionality')
      end

      it 'changes delete reference date' do
        CurationService.new(status: 'action_required', user_id: @user.id, resource_id: @resource.id).process
        refresh
        within(:css, '#activity_log_table tbody:last-child') do
          find('button[aria-label="Curation activity"]').click
        end
        click_button 'Edit notification date'
        fill_in('identifier_notification_date', with: Date.today + 2.months)
        fill_in('identifier[curation_activity][note]', with: 'Some Note')
        click_button('Submit')

        expect(page).to have_text("Changed notification start date to #{(Date.today + 1.month).strftime('%b %d, %Y')}.")
        expect(page).to have_text('Some Note')
      end

      it 'sets a flag' do
        expect(page).to have_text('Not flagged')
        click_button 'Edit Flag'
        expect(page).to have_text('Flag dataset')
        select 'Careful attention'
        click_button 'Submit'
        expect(page).to have_css('i.careful_attention')
        expect(page).to have_text('Careful attention')
      end

      it 'changes the submitter' do
        user = create(:user)
        create(:author, resource: @resource, author_orcid: user.orcid)
        expect(page).to have_text('Submitter:')
        click_button 'Edit submitter'
        expect(page).to have_text('Change dataset submitter')
        fill_in 'Enter the ORCID of the submitter user', with: user.orcid
        click_button 'Submit'
        expect(page).to have_text("Submitter: #{user.name}")
      end

      it 'edits publication dates' do
        create(:resource_published, user: @user, identifier: @identifier, tenant_id: @admin.tenant_id)
        refresh
        click_button 'Edit pub dates'
        expect(page).to have_text('Edit publication dates')
        expect(page).to have_text('Version 2 Publication date')
        fill_in find('input[type="date"]')[:name], with: Date.today - 1.day
        click_button 'Submit'
        expect(page).to have_text((Date.today - 1.day).strftime('%b %d, %Y'))
      end

      it 'edits related works' do
        allow_any_instance_of(StashDatacite::RelatedIdentifier).to receive(:live_url_valid?).and_return(true)
        click_button('Edit related works')
        expect(page).to have_text('Publication information')
        fill_in 'Publication name', with: 'Test journal'
        fill_in 'Manuscript number', with: 'TEST_MAN_1234'
        find('#pub_save').click
        click_button 'Close dialog', match: :first
        expect(page).to have_text('TEST_MAN_1234')
        click_button('Edit related works')
        select 'Primary article'
        fill_in 'DOI or other URL', with: Faker::Pid.doi
        within(:css, 'form[action="/stash_datacite/related_identifiers/create.js"]') do
          find('input[name="commit"]').click
        end
        expect(page).to have_css('form[action="/stash_datacite/related_identifiers/update.js"]')
        click_button 'Close dialog', match: :first
        expect(page).to have_text('TEST_MAN_1234')
        expect(page).to have_css('#doi-label')
        expect(page).to have_text('published')
      end

      it 'edits the funders' do
        new_funder = Faker::Company.name
        click_button 'Edit funders'
        expect(page).to have_text('+Add funder')
        within(:css, 'form[action="/stash_datacite/contributors/create.js"]') do
          fill_in 'Funder:', with: new_funder
          find('input[name="commit"]').click
        end
        click_button 'Close dialog', match: :first
        expect(page).not_to have_text('+Add funder')
        expect(page).to have_text(new_funder)
      end

      it 'sets a fee waiver and shows a log' do
        expect(page).to have_text('Payment:')
        click_button('Apply fee discount')
        expect(page).to have_text('Please provide a reason')
        find("#select_div option[value='no_funds']").select_option
        click_button('Submit')
        sleep 1
        click_button('View payment history')
        expect(page).to have_text('Payment history')
        expect(page).to have_text('Added waiver')
      end

      it 'adds a github issue' do
        expect(page).to have_text('Github issues')
        click_link 'Add github issue'
        fill_in 'Enter the issue number', with: '1235'
        click_button 'Submit'
        expect(page).to have_link('Another test github issue', href: 'https://github.com/datadryad/dryad-product-roadmap/issues/1235')
      end

      it 'adds an expression of concern' do
        concern = Faker::Lorem.paragraph
        expect(page).to have_text('Dangerous actions')
        expect(page).to have_button('Dataset usage warning')
        click_button 'Dataset usage warning'
        expect(page).to have_text('Notice/Expression of concern')
        find('[name="concern"]').send_keys(concern)
        expect(page).to have_text('Saved')
        click_button 'Close'
        click_link 'Landing page'
        expect(page).to have_text(concern)
      end
    end

    context :admin do
      before(:each) do
        create(:role, user: @user, role: 'admin')
        sign_in(@user, false)
        visit stash_url_helpers.admin_dashboard_path
        find('a[title="Activity log"]').click
        expect(page).to have_text('This is the dataset activity page.')
      end

      it 'allows adding notes to the curation activity log' do
        expect(page).to have_button('Add note')
      end

      it 'allows proper at a glance editing' do
        expect(page).to have_button('Edit Flag')
        expect(page).not_to have_button('Update status')
        expect(page).not_to have_button('Logout current editor')
        expect(page).not_to have_button('Edit pub dates')
        expect(page).not_to have_button('Edit related works')
        expect(page).not_to have_button('Edit funders')
        expect(page).not_to have_button('Edit submitter')
        expect(page).not_to have_button('View payment history')
        expect(page).not_to have_button('Apply fee discount')
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
        visit stash_url_helpers.admin_dashboard_path
        find('a[title="Activity log"]').click
        expect(page).to have_text('This is the dataset activity page.')
      end

      it 'allows adding notes to the curation activity log' do
        expect(page).to have_button('Add note')
      end

      it 'does not allow at a glance editing' do
        expect(page).not_to have_button('Edit Flag')
        expect(page).not_to have_button('Update status')
        expect(page).not_to have_button('Logout current editor')
        expect(page).not_to have_button('Edit pub dates')
        expect(page).not_to have_button('Edit related works')
        expect(page).not_to have_button('Edit funders')
        expect(page).not_to have_button('Edit submitter')
        expect(page).not_to have_button('View payment history')
        expect(page).not_to have_button('Apply fee discount')
      end
    end

    context :tenant_curator do
      before(:each) do
        mock_salesforce!
        @tenant_curator = create(:user)
        create(:role, user: @tenant_curator, role: 'curator', role_object: @tenant_curator.tenant)
        sign_in(@tenant_curator, false)
        visit stash_url_helpers.admin_dashboard_path
        find('a[title="Activity log"]').click
        expect(page).to have_text('This is the dataset activity page.')
      end

      it 'allows adding notes to the curation activity log' do
        expect(page).to have_button('Add note')
      end

      it 'allows proper at a glance editing' do
        expect(page).to have_button('Update status')
        expect(page).to have_button('Logout current editor')
        expect(page).to have_button('Edit pub dates')
        expect(page).to have_button('Edit related works')
        expect(page).to have_button('Edit funders')
        expect(page).to have_button('View payment history')
        expect(page).not_to have_button('Edit Flag')
        expect(page).not_to have_button('Edit submitter')
        expect(page).not_to have_button('Apply fee discount')
      end
    end
  end
end
