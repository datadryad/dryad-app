require 'rails_helper'

feature 'User lands on Home page and selects a Participating Partner' do

  scenario "User selects a Participating Partner from the list" do
    visit "/stash_engine"

    expect(page).to have_text("Get Started")
  end
end