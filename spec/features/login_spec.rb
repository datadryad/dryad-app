require 'features_helper'
require 'byebug'

describe 'login/logout' do
  before(:each) do
    visit('/')
    login = first(:link_or_button, 'Login')
    expect(login).not_to be_nil
    login.click
    select('Localhost', from: 'tenant_id')
    first(:link_or_button, 'Submit').click
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
