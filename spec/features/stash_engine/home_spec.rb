require 'rails_helper'

RSpec.feature 'HomePage', type: :feature do

  it 'resolves to the site "My datasets" when logged in' do
    sign_in
    visit root_path
    expect(page).to have_text('My datasets')
  end

  it 'resolves to the "Landing Page" when not logged in' do
    visit root_path
    expect(page).to have_css('.o-banner__tagline')
  end

end
