require 'rails_helper'

RSpec.feature 'DatasetVersioning', type: :feature do

  include MerrittHelper
  include DatasetHelper
  include Mocks::Repository
  include Mocks::RSolr

  describe :initial_version do

    before(:each) do
      mock_repository!
      mock_solr!
      @curator = create(:user, role: 'admin', tenant_id: 'dryad')
      @author = create(:user, tenant_id: 'dryad')
      @document_list = []
    end

    describe :pre_submit do

      it 'should display the proper info on the My Datasets page', js: true do
        initialize_new_dataset
        click_link 'My Datasets'

        within(:css, '#user_in_progress tbody tr:first-child') do
          expect(page).to have_text(@resource.title)
          expect(page).to have_text('In Progress')
          expect(page).to have_button('Resume')
          expect(page).to have_button('Delete')
        end
      end

    end

    describe :merritt_submission_error do

      it 'displays the proper information on the My Datasets page', js: true do
        initialize_new_dataset
        mock_unsuccessfull_merritt_submission(@resource)
        click_link 'My Datasets'
        within(:css, '#user_in_progress tbody tr:first-child') do
          expect(page).to have_text(@resource.title)
          expect(page).to have_text('In Progress')
          expect(page).to have_text('to fix this submission error')
          expect(page).to have_link('contact us')
        end
      end

    end

    describe :merrit_submission_sucess do

      before(:each) do
        initialize_new_dataset
      end

      it 'has a resource_state (Merritt status) of "submitted"', js: true do
        mock_successfull_merritt_submission(@resource)
        expect(@resource.submitted?).to eql(true)
      end

      it 'has a curation status of "submitted"', js: true do
        mock_successfull_merritt_submission(@resource)
        expect(@resource.current_curation_status).to eql('submitted')
      end

      it 'sent out an email to the author', js: true do
        expect(StashEngine::UserMailer).to receive(:status_change)
        mock_successfull_merritt_submission(@resource)
      end

      it 'displays the proper information on the My Datasets page', js: true do
        mock_successfull_merritt_submission(@resource)
        click_link 'My Datasets'
        within(:css, '#user_submitted tbody tr:first-child') do
          expect(page).to have_text(@resource.title)
          expect(page).to have_text('Submitted')
          expect(page).to have_button('Update')
        end
      end

      describe :when_viewed_by_curator do

        before(:each) do
          mock_successfull_merritt_submission(@resource)
          sign_out
          sign_in(@curator)
          click_link 'Admin'
        end

        it 'displays the proper information on the Admin page', js: true do
          within(:css, ".c-lined-table__row") do
            # Make sure the appropriate buttons are available
            expect(page).not_to have_css('button[title="Edit Dataset"]')
            expect(page).to have_css('button[title="Update Status"]')

            # Make sure the right text is shown
            expect(page).to have_link(@resource.title)
            within(:css, "#js-curation-state-#{@resource.id}") do
              expect(page).to have_text('Submitted')
            end
            expect(page).to have_text(@author.name)
            expect(page).not_to have_text(@curator.name)
            expect(page).to have_text(@resource.identifier)

            within(:css, ".js-embargo-state-#{@resource.id}") do
              expect(page).to have_text('')
            end
          end
        end

        it 'displays the proper information on the Activity Log page', js: true do
          within(:css, '.c-lined-table__row') do
            find('button[title="View Activity Log"]').click
            expect(page).to have_text(@resource.identifier)

            within(:css, 'c-lined-table__row:last-child') do
              expect(page).to have_text('Submitted')
              expect(page).to have_text(@author.name)
              expect(page).to have_text('submission successful')
            end
          end
        end

      end

    end

  end

  describe :new_version_by_curator do

    it 'has a resource_state (Merritt status) of "submitted"', js: true do

    end

    it 'has a curation status of "curation"', js: true do

    end

    it 'carried over the curation notes to the curation_activity record', js: true do

    end

    it 'did not send out an email to the author', js: true do

    end

    it 'displays the proper information on the Admin page', js: true do

    end

    it 'displays the proper information on the Activity Log page', js: true do

    end

  end

  describe :new_version_by_author do

    it 'has a resource_state (Merritt status) of "submitted"', js: true do

    end

    it 'has a curation status of "curation"', js: true do

    end

    it 'did not send out an email to the author', js: true do

    end

    it 'displays the proper information on the Admin page', js: true do

    end

    it 'displays the proper information on the Activity Log page', js: true do

    end

  end

  describe :peer_review do

    describe :initial_version do

      it 'has a resource_state (Merritt status) of "submitted"', js: true do

      end

      it 'has a curation status of "peer_review"', js: true do

      end

      it 'sent out an email to the author', js: true do

      end

    end

    describe :version_two do

      it 'has a resource_state (Merritt status) of "submitted"', js: true do

      end

      it 'has a curation status of "submitted"', js: true do

      end

      it 'did not send out an email to the author', js: true do

      end

    end

  end

  def initialize_new_dataset
    # Sign in and create a new dataset
    sign_in(@author)
    visit root_path
    click_link 'My Datasets'
    start_new_dataset
    fill_required_fields
    navigate_to_review
    submit_form
    @resource = StashEngine::Resource.where(user: @author).last
  end

end
