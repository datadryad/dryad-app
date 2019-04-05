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
      expect(page).to have_text('My Datasets')
    end

    it 'New user signs up successfully with ORCID and selects an organization', js: true do
      sign_in(@user, true)
      expect(page).to have_text('My Datasets')
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
      expect(page).to have_text('My Datasets')
    end

  end

end
