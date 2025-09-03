require 'rails_helper'
RSpec.feature 'MultipleEditors', type: :feature, js: true do

  include DatasetHelper
  include Mocks::Aws

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
        page.send_keys(:tab)
        click_button 'Invite to edit'
        expect(page).to have_text('You may invite this author as a collaborator on the submission.')
        select 'Collaborate'
        click_button 'Invite'
        expect(page).to have_content('Collaboration invitation sent!')
        within(:css, '[id^="invite-dialog"]') do
          click_button 'Close', match: :first
        end
        expect(StashEngine::Author.last&.edit_code&.role).to eq('collaborator')
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

    context 'accepting invitation' do
      let(:resource) { create(:resource, user: creator) }
      let(:authors) do
        [create(:author,
                resource: resource, author_first_name: creator.first_name, author_last_name: creator.last_name,
                author_orcid: creator.orcid, author_email: creator.email)] +
        2.times.map { create(:author, resource: resource, author_orcid: nil) }
      end

      before(:each) do
        mock_aws!
        authors.last.create_edit_code(role: 'collaborator')
      end

      it 'redirects to login' do
        visit accept_invite_path(authors.last.edit_code.edit_code)
        expect(page).to have_text('You must log in to accept this invitation.')
      end

      it 'does not accept twice' do
        authors.last.edit_code.update(applied: true)
        sign_in(create(:user))
        visit accept_invite_path(authors.last.edit_code.edit_code)
        expect(page).to have_text('This invitation has already been accepted.')
      end

      it 'does not accept for deleted datasets' do
        resource.destroy
        sign_in(create(:user))
        visit accept_invite_path(authors.last.edit_code.edit_code)
        expect(page).to have_text('The dataset you are looking for no longer exists.')
      end

      it 'lets a collaborator accept' do
        sign_in(create(:user))
        visit accept_invite_path(authors.last.edit_code.edit_code)
        expect(page).to have_text("You may now collaborate on #{resource.title&.html_safe}")
        expect(page).to have_css('#user_datasets li', count: 1)
      end

      it 'lets a submitter accept' do
        authors.last.edit_code.update(role: 'submitter')
        sign_in(create(:user))
        visit accept_invite_path(authors.last.edit_code.edit_code)
        expect(page).to have_text("You may now collaborate on #{resource.title&.html_safe}")
        expect(page).to have_css('#user_datasets li', count: 1)
        expect(resource.submitter.id).not_to eq(creator.id)
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
