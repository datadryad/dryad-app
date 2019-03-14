require 'rails_helper'

RSpec.feature 'Session', type: :feature do

  context 'ORCID Login' do

    let(:user) { create(:user, orcid: nil, tenant_id: nil) }

    it 'New user signs up successfully with ORCID and does not select an organization' do
      sign_in(user, false)
      expect(page).to have_text('My Datasets')
    end

    it 'New user signs up successfully with ORCID and selects an organization' do
      sign_in(user, true)
      expect(page).to have_text('My Datasets')
    end

    it 'User fails ORCID authentication' do
      # OmniAuth.config.test_mode = true
      # OmniAuth.config.add_mock(:orcid, uid: nil, credentials: {}, info: {}, extra: {})
      # visit root_path
      # click_link 'Login'
      # click_link 'Login or create your ORCID iD'
      # User should have been redirected to the homepage
      # expect(page).to have_text('Login')
    end

    it 'existing user signs in successfully' do
      sign_in(create(:user))
      expect(page).to have_text('My Datasets')
    end

  end

end
