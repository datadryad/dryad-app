require 'rails_helper'
feature 'User Authentication' do

  background do
    @tenant = StashEngine::Tenant.find('dataone')
    @user = StashEngine::User.create(first_name: 'test', last_name: 'user', email: 'testuser.ucop@gmail.com', tenant_id: @tenant.tenant_id)
  end

  scenario 'Signing in google authentication succssfully', js: true do
    visit "https://#{@tenant.full_domain}/stash/dashboard"
    within('#gaia_loginform') do
      fill_in 'Email', with: 'testuser.ucop@gmail.com'
      click_button 'Next'
      fill_in 'Password', with: 'secret123'
      click_button 'Sign in'
    end
    if page.has_content?('My Datasets: Getting Started') == true
      click_button 'Start New Dataset'
    else
      click_button 'Resume'
    end
    expect(page).to have_content 'Describe Your Datasets'
    click_button 'Logout'
    current_path.should == '/stash/'
  end
end
