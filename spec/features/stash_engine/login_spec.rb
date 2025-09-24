require 'rails_helper'

RSpec.feature 'Session', type: :feature do

  include Mocks::RSolr
  before(:each) do
    create(:tenant)
  end

  describe :orcid_login do

    before(:each) do
      mock_solr!
      @user = create(:user, tenant_id: nil, orcid: nil)
    end

    it 'New user signs up successfully with ORCID and does not select an organization', js: true do
      sign_in(@user)
      expect(page).to have_text('My datasets')
    end

    it 'New user signs up successfully with ORCID and selects an organization', js: true do
      sign_in(@user, true)
      expect(page).to have_text('My datasets')
    end

    it 'existing user signs in successfully', js: true do
      sign_in
      expect(page).to have_text('My datasets')
    end

  end

  describe :test_login do
    before(:each) do
      ENV['TEST_LOGIN'] = 'true'
    end

    after(:each) do
      ENV.delete('TEST_LOGIN')
    end

    it 'has a link in the login page' do
      visit stash_url_helpers.choose_login_path
      expect(page).to have_text('Use test login')
    end

    it 'allows filling the form and logging in' do
      visit stash_url_helpers.choose_login_path
      click_link 'Use test login'

      expect(page).to have_text('First name') # just one of the fields

      fill_in 'first_name', with: 'Gloria'
      fill_in 'last_name', with: 'Clooney'
      fill_in 'email', with: 'gloria.clooney@example.org'
      fill_in 'orcid', with: '1234-5678-9012-3456'
      click_button('Log In')
      expect(page).to have_text('My datasets')
    end
  end

  describe :other_authentication, js: true do

    before(:each) do
      create(:tenant_match)
      create(:tenant_email)
      @user = create(:user, tenant_id: nil)
      mock_orcid!(@user)
      OmniAuth.config.test_mode = true
      visit root_path
      click_link 'Login'
    end

    # for author match authentication
    it 'logs in without shibboleth auth for configured tenant' do
      click_link 'Login or create your ORCID iD'
      find('#searchselect-tenant__input').click
      within('#searchselect-tenant__list') do
        find('li', text: 'Match Tenant').click
      end
      click_button 'Login to verify'
      expect(page).to have_text('My datasets')
      expect(page).to have_text('match_tenant')
    end

    # for email authentication
    it 'sends and requires a code for configured tenant' do
      click_link 'Login or create your ORCID iD'
      find('#searchselect-tenant__input').click
      within('#searchselect-tenant__list') do
        find('li', text: 'Email Test').click
      end
      click_button 'Login to verify'
      expect(page).to have_text('Enter confirmation code')
      # enter and erase email
      fill_in 'email', with: 'test@example.org'
      click_button 'Save email'
      click_button 'Enter a new email address'
      fill_in 'email', with: 'test@example.org'
      click_button 'Save email'
      expect(page).to have_text('Enter confirmation code')
      # refresh code
      click_link 'Send another code'
      expect(page).to have_text('Enter confirmation code')
      # enter code
      fill_in 'email_code', with: StashEngine::EmailToken.all.last.token
      expect(page).to have_text('My datasets')
      expect(page).to have_text('email_auth')
    end
  end

  describe :reauthentication, js: true do

    before(:each) do
      @tenant = create(:tenant_email)
      @user = create(:user, tenant_id: @tenant.id, tenant_auth_date: 2.months.ago)
      mock_orcid!(@user)
      OmniAuth.config.test_mode = true
      sign_in(@user)
      visit root_path
      click_link 'My datasets'
    end

    it 'requries reauthentication when auth date is more than 1 month ago' do
      expect(page).to have_text('email_auth')
      expect(page).to have_text('Reconnect')
    end

    it 'successfully reauthenticates' do
      expect(page).to have_text('Reconnect')
      click_button 'Login to verify'
      expect(page).to have_text('Enter confirmation code')
      # enter and erase email
      fill_in 'email', with: 'test@example.org'
      click_button 'Save email'
      click_button 'Enter a new email address'
      fill_in 'email', with: 'test@example.org'
      click_button 'Save email'
      expect(page).to have_text('Enter confirmation code')
      # refresh code
      click_link 'Send another code'
      expect(page).to have_text('Enter confirmation code')
      # enter code
      fill_in 'email_code', with: StashEngine::EmailToken.all.last.token
      expect(page).to have_text('My datasets')
      expect(page).to have_text('email_auth')
    end
  end
end
