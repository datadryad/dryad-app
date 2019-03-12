require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'MigrateData', type: :feature do

  before(:all) do
    # Start Solr - shutdown is handled globally when all tests have finished
    SolrInstance.instance
  end

  before(:each) do
    @user = create(:user, migration_token: Faker::Lorem.word)
    create(:resource, :submitted, user: @user, identifier: create(:identifier))
    sign_in(@user)
    visit stash_url_helpers.dashboard_path
  end

  context :message_visibility do

    it 'displays the message on the "My Datasets" page' do
      expect(page).to have_text('Are you missing data')
    end

    it 'permanantly hides migration info when the user clicks "No"', js: true do
      click_button 'No'
      visit stash_url_helpers.dashboard_path
      expect(page).not_to have_text('Are you missing data')
    end

  end

  context :clicked_yes do

    before(:all) do
      # Start Solr - shutdown is handled globally when all tests have finished
      SolrInstance.instance
    end

    it 'goes to migration if clicking yes in migrate banner dialog' do
      click_button 'Yes. Migrate my data.'
      expect(page).to have_text('Migrate Your Data')
    end

    it 'finishes migration', js: true do
      @user.update(migration_token: Faker::Number.number(6))
      @user.reload
      visit stash_url_helpers.auth_migrate_mail_path
      fill_in 'code', with: @user.migration_token
      click_button 'Migrate data'
      expect(page).to have_text('Your old Dryad data packages and submissions have now been connected')
    end

    context :invalid_request do

      it 'gives error for badly formatted email' do
        visit stash_url_helpers.auth_migrate_mail_path
        fill_in 'email', with: 'brr'
        click_button 'Send code'
        expect(page).to have_text('Please fill in a correct email address')
      end

      it 'gives error for badly formatted code' do
        visit stash_url_helpers.auth_migrate_mail_path
        fill_in 'code', with: 'yack'
        click_button 'Migrate data'
        expect(page).to have_text('Please enter your correct 6-digit code to migrate your data')
      end

      it 'errors with a bad code' do
        visit stash_url_helpers.auth_migrate_mail_path
        fill_in 'code', with: '000000'
        click_button 'Migrate data'
        expect(page).to have_text('The code you entered is incorrect')
      end

      it 'locks out with too many guesses' do
        visit stash_url_helpers.auth_migrate_mail_path
        5.times do
          fill_in 'code', with: '000000'
          click_button 'Migrate data'
          expect(page).to have_text('The code you entered is incorrect')
        end
        fill_in 'code', with: '000000'
        click_button 'Migrate data'
        expect(page).to have_text("You've had too many incorrect code validation attempts.")
      end

    end

  end

end
# rubocop:enable Metrics/BlockLength
