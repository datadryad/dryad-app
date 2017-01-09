require 'rails_helper'
require 'database_cleaner'

feature "User lands on metadata entry page and navigates through it" do

  it "Logged in user fills metadata entry page", js: true do
    visit "localhost:3000/stash"
    first(:link, 'Explore Data').click

    find('#q').set('Test Dataset')
    click_button 'Search'
    expect(page).to have_content 'Test Dataset'

    first(:link, 'Author').click
    click_link 'more'
    click_link('user, test')
    expect(page).to have_content 'Test Dataset'

    click_link 'Start Over'
  end
end
