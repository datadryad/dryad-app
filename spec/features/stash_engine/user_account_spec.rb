RSpec.feature 'UserAccount', type: :feature, js: true do

  describe 'user account page' do
    let(:user) { create(:user) }
    before(:each) do
      sign_in(user)
      visit my_account_path
    end

    context 'account editing' do
      let(:fn) { Faker::Name.first_name }
      let(:ln) { Faker::Name.last_name }
      let(:em) { Faker::Internet.email }

      it 'shows the account form' do
        expect(page).to have_text('My account')
        expect(page).to have_field('First name', with: user.first_name)
        expect(page).to have_field('Last name', with: user.last_name)
        expect(page).to have_field('Email', with: user.email)
      end

      it 'updates the user' do
        expect(page).to have_field('First name', with: user.first_name)
        expect(page).to have_field('Last name', with: user.last_name)
        expect(page).to have_field('Email', with: user.email)

        fill_in 'First name', with: fn
        fill_in 'Last name', with: ln

        click_button 'Save changes'
        find_button 'Save changes', disabled: true
        expect(page).to have_field('First name', with: fn)
        expect(page).to have_field('Last name', with: ln)
      end

      it 'reverifies any new email address' do
        expect(page).to have_field('Email', with: user.email)
        fill_in 'Email', with: em
        page.send_keys(:tab)
        click_button 'Save changes'

        expect(page).to have_content('Verify your email address')
        fill_in 'email_code', with: StashEngine::EmailToken.all.last.token

        expect(page).to have_field('Email', with: em)
      end
    end

    context 'duplicate accounts' do
      let(:other_user) { create(:user) }

      it 'shows the ORCID error message' do
        fill_in 'Email', with: other_user.email
        page.send_keys(:tab)
        click_button 'Save changes'
        expect(page).to have_content("The email address #{other_user.email} belongs to another account")
        expect(page).to have_link('remove any duplicate ORCIDs and merge your Dryad accounts')
      end

      context 'with merge request' do
        before(:each) do
          create(:resource, user: other_user)
          other_user.update(orcid: nil)
        end

        it 'shows the Email error message' do
          fill_in 'Email', with: other_user.email
          page.send_keys(:tab)
          click_button 'Save changes'
          expect(page).to have_content("The email address #{other_user.email} belongs to another account")
          expect(page).to have_button('Request these accounts be merged')
        end

        it 'requests the account merge' do
          fill_in 'Email', with: other_user.email
          page.send_keys(:tab)
          click_button 'Save changes'
          click_button('Request these accounts be merged')
          expect(page).to have_content('Your request has been sent and will be processed as soon as possible.')
        end
      end
    end

    context 'API account' do
      it 'shows the API account options' do
        expect(page).to have_text('API account')
        expect(page).to have_text('No API account exists for this user.')
        expect(page).to have_button('Create a Dryad API account')
      end

      it 'creates the API account' do
        click_button 'Create a Dryad API account'
        expect(page).to have_text('Account ID:')
        expect(page).to have_text('Secret:')
        expect(page).to have_text('Token:')
        expect(page).to have_text('Expires in:')
      end
    end
  end
end
