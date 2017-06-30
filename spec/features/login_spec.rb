require 'features_helper'

describe 'login/logout' do
  before(:each) do
    allow(StashEngine::Tenant).to(receive(:google_login_path)
      .and_wrap_original) { |m| m.call.sub('https', 'http') }
    visit('/')
  end

  describe 'Login' do
    it 'goes to Getting Started when no datasets exist' do
      login_link = first(:link, 'Login')
      expect(login_link[:href]).to eq('http://localhost:33000/stash/auth/google_oauth2')
      login_link.click
      expect(page).to have_content('My Datasets: Getting Started')
    end
  end

  describe 'Logout' do
    it 'returns to the home page' do
      first(:link, 'Login').click
      expect(page).to have_content('Logout')
      first(:link, 'Logout').click
      expect(page).to have_title(home_page_title)
    end
  end

end
