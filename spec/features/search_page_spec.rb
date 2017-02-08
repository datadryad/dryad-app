require 'rails_helper'

def wait_for_ajax
  Capybara.default_max_wait_time = 500
end

# def finished_all_ajax_requests?
#     page.evaluate_script("jQuery.active") == 0
# end

feature "User lands on metadata entry page and navigates through it" do

  it "Logged in user fills metadata entry page", js: true do
    visit "localhost:3000/stash"
    sleep 5
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
