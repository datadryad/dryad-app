require 'rails_helper'

RSpec.feature 'Session', type: :feature do

  include Mocks::RSolr

  describe :orcid_login do

    before(:each) do
      mock_solr!
      @user = create(:user, role: 'user', tenant_id: nil, orcid: nil)
    end

    it 'New user signs up successfully with ORCID and does not select an organization', js: true do
      sign_in(@user)
      expect(page).to have_text('My datasets')
    end

    it 'New user signs up successfully with ORCID and selects an organization', js: true do
      sign_in(@user, true)
      expect(page).to have_text('My datasets')
    end

    it 'User fails ORCID authentication', js: true do
      # OmniAuth.config.test_mode = true
      # OmniAuth.config.add_mock(:orcid, uid: nil, credentials: {}, info: {}, extra: {})
      # visit root_path
      # click_link 'Login'
      # click_link 'Login or create your ORCID iD'
      # User should have been redirected to the homepage
      # expect(page).to have_text('Login')
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

  # for author match authentication
  describe :author_match, js: true do

    before(:each) do
      user = create(:user, tenant_id: nil)
      mock_orcid!(user)
      OmniAuth.config.test_mode = true
      visit root_path
      click_link 'Login'
    end

    it 'logs in without shibboleth auth for configured tenant' do
      click_link 'Login or create your ORCID iD'
      select 'DataONE', from: 'tenant_id'
      click_button 'Login to verify'
      expect(page).to have_text('My datasets')
    end
  end
end
