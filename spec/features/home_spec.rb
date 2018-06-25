require 'features_helper'

# TODO: switch to Capybara scenario style
describe 'home' do
  before(:each) do
    visit('/')
  end

  it 'redirects to /stash' do
    expect(page).to have_current_path('/stash')
  end

  it 'is the home page' do
    expect(page).to have_title(home_page_title)
  end
end
