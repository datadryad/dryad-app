RSpec.feature 'AdminSearch', type: :feature do
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
    create(:tenant)
    @user = create(:user, tenant_id: 'test_tenant')
    @superuser = create(:user, role: 'superuser')
    3.times do
      identifier = create(:identifier)
      create(:resource, :submitted, user: @user, identifier: identifier)
    end
  end

  it 'saves search settings', js: true do
    sign_in(@superuser, false)
    visit stash_url_helpers.admin_dashboard_path
    expect(page).to have_text('Admin dashboard')
    check 'submitter'
    check 'metrics'
    click_button('Apply')
    expect(find('thead')).to have_text('Submitter')
    expect(find('thead')).to have_text('Metrics')
    click_button('Save search')
    fill_in('title', with: 'Search test')
    click_button('Submit')
    expect(find('#search_head')).to have_text('Search test')
  end

  context :saved_search do
    before(:each) do
      # rubocop:disable Layout/LineLength
      @properties = '{"fields":["doi","authors","submitter"],"filters":{"member":"","status":"","curator":"","journal":{"value":"","label":""},"sponsor":"","funder":{"value":"","label":""},"affiliation":{"value":"","label":""},"updated_at":{"start_date":"","end_date":""},"submit_date":{"start_date":"","end_date":""},"publication_date":{"start_date":"","end_date":""},"identifiers":""},"search_string":""}'
      # rubocop:enable Layout/LineLength
      @superuser.admin_searches << StashEngine::AdminSearch.create(title: 'First saved search', properties: @properties)
    end

    it 'shows shared search', js: true do
      @superuser.admin_searches.first.create_code
      sign_in(create(:user, role: 'admin'))
      visit stash_url_helpers.admin_dashboard_path(share: @superuser.admin_searches.first.share_code)
      expect(page).to have_text('Admin dashboard')
      expect(page).to have_text('First saved search')
      expect(find('#search_head')).not_to have_text('First saved search')
      expect(page).to have_text('Display fields')
      expect(find('#submitter')).to be_checked
      expect(find('thead')).to have_text('Submitter')
      expect(page).to have_button('Save search')
    end

    context :search_properties do
      before(:each) do
        sign_in(@superuser, false)
      end
      it 'does not show saved search', js: true do
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(find('#search_head')).not_to have_text('First saved search')
        expect(find('#submitter')).not_to be_checked
        expect(find('thead')).not_to have_text('Submitter')
      end
      it 'shows saved search', js: true do
        visit stash_url_helpers.admin_dashboard_path(search: 1)
        expect(page).to have_text('Admin dashboard')
        expect(find('#search_head')).to have_text('First saved search')
        click_button('Fields and filters')
        expect(page).to have_text('Display fields')
        expect(find('#submitter')).to be_checked
        expect(find('thead')).to have_text('Submitter')
      end
      it 'shows default saved search', js: true do
        @superuser.admin_searches.first.update(default: true)
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(find('#search_head')).to have_text('First saved search')
        click_button('Fields and filters')
        expect(page).to have_text('Display fields')
        expect(find('#submitter')).to be_checked
        expect(find('thead')).to have_text('Submitter')
      end
      it 'edits saved search', js: true do
        visit stash_url_helpers.admin_dashboard_path(search: 1)
        expect(page).to have_text('Admin dashboard')
        expect(find('#search_head')).to have_text('First saved search')
        click_button('Fields and filters')
        expect(page).not_to have_css('#searh_form[hidden]')
        check 'metrics'
        click_button('Apply')
        click_button('Save search changes')
        visit stash_url_helpers.admin_dashboard_path(search: 1)
        expect(page).to have_text('Admin dashboard')
        expect(find('#search_head')).to have_text('First saved search')
        click_button('Fields and filters')
        expect(page).to have_text('Display fields')
        expect(find('#metrics')).to be_checked
        expect(find('thead')).to have_text('Metrics')
      end
      it 'replaces search default', js: true do
        @superuser.admin_searches.first.update(default: true)
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(find('#search_head')).to have_text('First saved search')
        click_button('Fields and filters')
        expect(page).not_to have_css('#searh_form[hidden]')
        check 'metrics'
        click_button('Apply')
        click_button('Save as new search')
        fill_in('title', with: 'New default search')
        check 'default'
        click_button('Submit')
        expect(find('#search_head')).to have_text('New default search')
        visit stash_url_helpers.admin_dashboard_path
        expect(page).to have_text('Admin dashboard')
        expect(find('#search_head')).to have_text('New default search')
        click_button('Fields and filters')
        expect(page).to have_text('Display fields')
        expect(find('#metrics')).to be_checked
        expect(find('thead')).to have_text('Metrics')
      end
    end

    context :search_profile do
      before(:each) do
        sign_in(@superuser, false)
      end
      it 'has a search share code', js: true do
        visit stash_url_helpers.my_account_path
        expect(find('#admin_searches_list')).to have_text('First saved search')
        expect(@superuser.admin_searches.first.share_code).not_to eq(nil)
        expect(page).to have_link(nil, href: admin_dashboard_path(share: @superuser.admin_searches.first.share_code, clear: true))
      end
      it 'edits search details', js: true do
        visit stash_url_helpers.my_account_path
        expect(find('#admin_searches_list')).to have_text('First saved search')
        within(find('#admin_searches_list li:first-child')) do
          click_button 'Edit search description'
        end
        fill_in('title', with: 'Edited search')
        within(find('#admin_searches_list li:first-child')) do
          click_button 'Save'
        end
        expect(find('#admin_searches_list')).to have_text('Edited search')
      end
      it 'replaces search default', js: true do
        @superuser.admin_searches << StashEngine::AdminSearch.create(title: 'First default search', properties: @properties, default: true)
        visit stash_url_helpers.my_account_path
        expect(find('#admin_searches_list'))
        expect(find('#admin_searches_list')).to have_text('First saved search')
        expect(find('#admin_searches_list')).to have_text('First default search')
        expect(find('#admin_searches_list li:last-child')).to have_text('Default')
        within(find('#admin_searches_list li:first-child')) do
          click_button 'Edit search description'
        end
        expect(find('#admin_searches_list')).to match_css('.with_form')
        check 'default'
        within(find('#admin_searches_list li:first-child')) do
          click_button 'Save'
        end
        expect(find('#admin_searches_list li:first-child')).to have_text('Default')
        expect(find('#admin_searches_list li:last-child')).not_to have_text('Default')
      end
    end
  end
end
