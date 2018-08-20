require 'features_helper'
require 'byebug'

describe 'migrate_data ' do
  before(:each) do
    log_in!
  end

  it 'shows migrate data' do
    expect(page).to have_text('Are you missing data')
  end

  it "makes 'no' in migrate dialog permanantly hide migration info" do
    first(:link_or_button, 'No').click
    visit('/stash/dashboard')
    expect(page.has_no_text?('Are you missing data')).to eq(true)
  end

  it 'goes to migration if clicking yes in migrate banner dialog' do
    first(:link_or_button, 'Yes. Migrate my data.').click
    expect(page).to have_text('Migrate Your Data')
  end

  it 'gives error for badly formatted email' do
    visit('/stash/auth/migrate/mail')
    fill_in 'email', with: 'brr'
    first(:link_or_button, 'Send code').click
    expect(page).to have_text('Please fill in a correct email address')
  end

  it 'gives error for badly formatted code' do
    visit('/stash/auth/migrate/mail')
    fill_in 'code', with: 'yack'
    first(:link_or_button, 'Migrate data').click
    expect(page).to have_text('Please enter your correct 6-digit code to migrate your data')
  end

  it 'errors with a bad code' do
    visit('/stash/auth/migrate/mail')
    fill_in 'code', with: '000000'
    first(:link_or_button, 'Migrate data').click
    expect(page).to have_text('The code you entered is incorrect')
  end

  it 'locks out with too many guesses' do
    visit('/stash/auth/migrate/mail')
    5.times do
      fill_in 'code', with: '000000'
      first(:link_or_button, 'Migrate data').click
      expect(page).to have_text('The code you entered is incorrect')
    end
    fill_in 'code', with: '000000'
    first(:link_or_button, 'Migrate data').click
    expect(page).to have_text("You've had too many incorrect code validation attempts.")
  end

  it 'finishes migration if right code is entered' do
    visit('/stash/auth/migrate/mail')
    valid_token = ActiveRecord::Base.connection.select_all('SELECT * FROM stash_engine_users').first['migration_token']
    fill_in 'code', with: valid_token
    first(:link_or_button, 'Migrate data').click
    expect(page).to have_text('Your old Dryad data packages and submissions have now been connected')
  end

end
