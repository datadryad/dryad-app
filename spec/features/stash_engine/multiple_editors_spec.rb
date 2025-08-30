require 'rails_helper'
RSpec.feature 'MultipleEditors', type: :feature, js: true do

  include DatasetHelper

  describe 'multiple editor functionality' do
    let(:creator) { create(:user) }
    let(:submitter) { create(:user) }

    context 'inviting editors' do
      before(:each) do
        allow(StashEngine::UserMailer).to receive_message_chain(:invite_author, :deliver_now).and_return(true)
        allow(StashEngine::UserMailer).to receive_message_chain(:invite_user, :deliver_now).and_return(true)
        sign_in(creator)
        start_new_dataset
        click_button 'Title'
        fill_in_title
        click_button 'Authors'
        fill_in_affiliation
      end

      it 'invites an author who is a user' do
        click_button('Add author')
        within(:css, '.dd-list-item:not(:first-child)') do
          fill_in_author(first_name: submitter.first_name, last_name: submitter.last_name, email: submitter.email)
        end
        click_button 'Invite to edit'
        expect(page).to have_text("Invite #{submitter.name}")
        select 'Collaborate'
        click_button 'Invite'
        expect(page).to have_content('Collaboration invitation sent!')
        within(:css, '[id^="invite-dialog"]') do
          click_button 'Close', match: :first
        end
        expect(submitter.resources.length).to eq 1
        expect(submitter.roles.first.role).to eq 'collaborator'
      end

      it 'invites a new author' do
        click_button('Add author')
        within(:css, '.dd-list-item:not(:first-child)') do
          fill_in_author
        end
        click_button 'Invite to edit'
        expect(page).to have_text('You may invite this author as a collaborator on the submission.')
        select 'Collaborate'
        click_button 'Invite'
        expect(page).to have_content('Collaboration invitation sent!')
        within(:css, '[id^="invite-dialog"]') do
          click_button 'Close', match: :first
        end
        expect(page).to have_text('Invited collaborator')
      end

      it 'invites an author as a submitter' do
        click_button('Add author')
        within(:css, '.dd-list-item:not(:first-child)') do
          fill_in_author(first_name: submitter.first_name, last_name: submitter.last_name, email: submitter.email)
        end
        click_button 'Invite to edit'
        expect(page).to have_text("Invite #{submitter.name}")
        select 'Collaborate and submit'
        click_button 'Invite'
        expect(page).to have_content('Collaboration invitation sent!')
        within(:css, '[id^="invite-dialog"]') do
          click_button 'Close', match: :first
        end
        expect(submitter.resources.length).to eq 1
        expect(submitter.roles.first.role).to eq 'submitter'
      end
    end

    context 'switching editors' do
      let(:resource) { create(:resource, user: creator) }

      before(:each) do
        resource.submitter = submitter.id
        resource.reload
      end

      it 'shows editor button correctly' do
        sign_in(creator)
        expect(page).to have_button('Resume')
        expect(page).to have_button('Save & exit')
      end

      it 'shows non-editor no button' do
        sign_in(submitter)
        expect(page).to have_text('In progress with another user')
        expect(page).to have_text("#{creator.name} is editing")
      end

      it 'allows the editor to sign out and another editor to take over' do
        sign_in(creator)
        click_button 'Save & exit'
        expect(page).to have_button('Edit')
        sign_out

        sign_in(submitter)
        expect(page).to have_text('Needs attention')
        expect(page).to have_button('Edit')
        click_button 'Edit'
        expect(page).to have_text('Dataset submission')
        sign_out

        sign_in(creator)
        expect(page).to have_text('In progress with another user')
        expect(page).to have_text("#{submitter.name} is editing")
      end
    end
  end
end
