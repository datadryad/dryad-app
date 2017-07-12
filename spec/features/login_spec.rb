require 'features_helper'
require 'byebug'

# TODO: switch to Capybara scenario style
describe 'login/logout' do
  before(:each) do
    visit('/')
    login = first(:link_or_button, 'Login')
    expect(login).not_to be_nil
    login.click
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
