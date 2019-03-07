require 'features_helper'

describe 'login/logout' do
  before(:each) do
    visit('/')
    login = first(:link_or_button, 'Login')
    expect(login).not_to be_nil
    login.click
    first(:link_or_button, 'Login or create your ORCID iD').click
    first(:link_or_button, 'Continue to My Datasets').click
  end

  describe 'Login' do
    it 'goes to My Datasets page when no datasets exist' do
      expect(page).to have_content('My Datasets')
    end
  end

  describe 'Logout' do
    it 'returns to the home page' do
      logout = first(:link_or_button, 'Logout')
      expect(logout).not_to be_nil
      logout.click
      expect(page).to have_title(home_page_title)
    end
  end

end
