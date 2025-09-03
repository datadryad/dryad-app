RSpec.feature 'Contact', type: :feature, js: true do
  include Mocks::Salesforce

  context 'use contact form' do
    let(:user) { create(:user) }

    before(:each) do
      mock_email_case!
      sign_in(user)
      visit contact_path
    end

    it 'displays the form' do
      expect(page).to have_text('Help needed with:')
      expect(page).to have_text('Your full name:')
      expect(page).to have_text('Your email address:')
    end

    it 'shows an error if the form is incomplete' do
      select 'Status of my dataset'
      fill_in 'body', with: ' '
      click_button 'Contact the helpdesk'
      expect(page).to have_text('Please fill all required fields')
    end

    it 'submits the completed form' do
      select 'Status of my dataset'
      fill_in 'body', with: Faker::Lorem.paragraph
      click_button 'Contact the helpdesk'
      expect(page).to have_text('Your query has been submitted to the Dryad helpdesk.')
    end

  end
end
