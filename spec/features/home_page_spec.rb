require 'rails_helper'

feature  :type => :feature do

  scenario "User logs in" do
    visit "/stash_engine"

    #click_button "Get Started"

    expect(page).to have_text("Get Started")
  end
end