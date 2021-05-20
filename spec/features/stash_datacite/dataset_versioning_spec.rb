require 'rails_helper'
RSpec.feature 'DatasetVersioning', type: :feature do

  include MerrittHelper
  include DatasetHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Ror
  include Mocks::Stripe
  include Mocks::Tenant

  before(:each) do
    mock_repository!
    mock_solr!
    mock_ror!
    mock_datacite_and_idgen!
    mock_stripe!
    mock_tenant!
    ignore_zenodo!
    neuter_curation_callbacks!
    @curator = create(:user, role: 'superuser')
    @author = create(:user)
    @document_list = []
  end

  describe :initial_version do

    before(:each, js: true) do
      ActionMailer::Base.deliveries = []
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

    describe :pre_submit do

      it 'should display the proper info on the My Datasets page', js: true do
        click_link 'My Datasets'

        within(:css, '#user_in_progress tbody tr:first-child') do
          expect(page).to have_text(@resource.title)
          expect(page).to have_text('In Progress')
          expect(page).to have_button('Resume')
          expect(page).to have_button('Delete')
        end
      end

      it 'did not send out an email to the author', js: true do
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end

    end

    describe :merritt_submission_error do

      it 'displays the proper information on the My Datasets page', js: true do
        mock_unsuccessfull_merritt_submission!(@resource)
        click_link 'My Datasets'
        within(:css, '#user_submitted tbody tr:first-child') do
          expect(page).to have_text(@resource.title)
          expect(page).to have_text('Processing')
          # Capybara matcher returns nil for the 'Update' link since it is disabled
          expect(page).not_to have_link('Update')
        end
      end

    end

    describe :merritt_submission_success do

      before(:each) do
        ActionMailer::Base.deliveries = []
        mock_successfull_merritt_submission!(@resource)
      end

      it 'has a resource_state (Merritt status) of "submitted"', js: true do
        expect(@resource.submitted?).to eql(true)
      end

      it 'has a curation status of "submitted"', js: true do
        expect(@resource.current_curation_status).to eql('submitted')
      end

      it 'displays the proper information on the My Datasets page', js: true do
        click_link 'My Datasets'
        within(:css, '#user_submitted tbody tr:first-child') do
          expect(page).to have_text(@resource.title)
          expect(page).to have_text('Submitted')
          expect(page).to have_button('Update')
        end
      end

      describe :when_viewed_by_curator do

        before(:each, js: true) do
          sign_in(@curator)
          find('summary', text: 'Admin').click
          click_link 'Dataset Curation'
        end

        it 'displays the proper information on the Admin page', js: true do
          within(:css, '.c-lined-table__row') do
            # Make sure the appropriate buttons are available
            # Curators want to edit everything unless it's in progress, so enjoy
            expect(page).to have_css('button[title="Edit Dataset"]')
            expect(page).to have_css('button[aria-label="Update status"]')

            # Make sure the right text is shown
            expect(page).to have_link(@resource.title)
            within(:css, "#js-curation-state-#{@resource.id}") do
              expect(page).to have_text('Submitted')
            end
            expect(page).to have_text(@resource.authors.collect(&:author_last_name).join('; '))
            expect(page).not_to have_text(@curator.name_last_first)
            expect(page).to have_text(@resource.identifier.identifier)
          end
        end

        it 'displays the proper information on the Activity Log page', js: true do
          within(:css, '.c-lined-table__row') do
            find('button[aria-label="View Activity Log"]').click
          end

          expect(page).to have_text(@resource.identifier)

          within(:css, '.c-lined-table__row:last-child') do
            expect(page).to have_text('Submitted')
            expect(page).to have_text(@author.name)
          end
        end

      end

    end

  end

  describe :new_version do

    before(:each) do
      ActionMailer::Base.deliveries = []
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, identifier: @identifier, user_id: @author.id, tenant_id: @author.tenant_id)
    end

    context :by_curator do

      before(:each, js: true) do
        # needed to set the user to system user.  Not migrated as part of tests for some reason
        StashEngine::User.create(id: 0, first_name: 'Dryad', last_name: 'System', role: 'user') unless StashEngine::User.where(id: 0).first

        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'curation')
        @resource.reload

        sign_in(@curator)
        find('summary', text: 'Admin').click
        click_link 'Dataset Curation'
        # Edit the Dataset as an admin
        find('button[title="Edit Dataset"]').click
        expect(page).to have_text("You are editing #{@author.name}'s dataset.")
        update_dataset(curator: true)
        @resource.reload
        find('summary', text: 'Admin').click
        click_link 'Dataset Curation'
      end

      it 'has a resource_state (Merritt status) of "submitted"', js: true do
        expect(@resource.submitted?).to eql(true)
      end

      it 'has a curation status of "curation"', js: true do
        expect(@resource.current_curation_status).to eql('curation')
      end

      it 'added a curation note to the record', js: true do
        expect(@resource.curation_activities.where(status: 'in_progress').last.note).to include(@resource.edit_histories.last.user_comment)
      end

      it 'displays the proper information on the Admin page', js: true do
        within(:css, '.c-lined-table__row') do

          # Make sure the appropriate buttons are available
          expect(page).to have_css('button[title="Edit Dataset"]')
          expect(page).to have_css('button[aria-label="Update status"]')

          # Make sure the right text is shown
          expect(page).to have_link(@resource.title)
          expect(page).to have_text('Curation')
          expect(page).to have_text(@resource.authors.collect(&:author_last_name).join('; '))
          expect(page).to have_text(@curator.name.to_s)
          expect(page).to have_text(@resource.identifier.identifier)
        end
      end

      it 'displays the proper information on the Activity Log page', js: true do
        within(:css, '.c-lined-table__row') do
          find('button[aria-label="View Activity Log"]').click
        end

        expect(page).to have_text(@resource.identifier)

        # it has the user comment when they clicked to submit and end in-progress edit
        expect(page).to have_text(@resource.edit_histories.last.user_comment)

        within(:css, '.c-lined-table__row:last-child') do
          expect(page).to have_text('Curation')
          expect(page).to have_text('Dryad System')
          expect(page).to have_text('system set back to curation')
        end
      end

    end

    context :by_author do

      before(:each, js: true) do
        ActionMailer::Base.deliveries = []
        sign_in(@author)
        click_link 'My Datasets'
        within(:css, '#user_submitted') do
          click_button 'Update'
        end
        update_dataset
        @resource.reload
      end

      it 'has a resource_state (Merritt status) of "submitted"', js: true do
        expect(@resource.submitted?).to eql(true)
      end

      it 'has a curation status of "submitted"', js: true do
        expect(@resource.current_curation_status).to eql('submitted')
      end

      # TODO: This is no longer tested the same way... may need to install capybara-email
      xit 'sends out a "submitted" email to the author', js: true do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it 'displays the proper information on the Admin page', js: true do
        sign_in(@curator)
        find('summary', text: 'Admin').click
        click_link 'Dataset Curation'
        within(:css, '.c-lined-table__row') do
          # Make sure the appropriate buttons are available
          # Make sure the right text is shown
          expect(page).to have_link(@resource.title)
          expect(page).to have_text('Submitted')
          expect(page).to have_text(@resource.authors.collect(&:author_last_name).join('; '))
          expect(page).not_to have_text(@curator.name_last_first)
          expect(page).to have_text(@resource.identifier.identifier)
        end
      end

      it 'displays the proper information on the Activity Log page', js: true do
        sign_in(@curator)
        find('summary', text: 'Admin').click
        click_link 'Dataset Curation'

        within(:css, '.c-lined-table__row') do
          find('button[aria-label="View Activity Log"]').click
        end

        expect(page).to have_text(@resource.identifier.identifier)

        within(:css, '.c-lined-table__row:last-child') do
          expect(page).to have_text('Submitted')
          expect(page).to have_text(@author.name)
        end
      end

    end

    context :by_author_after_curation do

      before(:each) do
        # needed to set the user to system user.  Not migrated as part of tests for some reason
        StashEngine::User.create(id: 0, first_name: 'Dryad', last_name: 'System', role: 'user') unless StashEngine::User.where(id: 0).first

        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'curation')
        @resource.reload
      end

      it "has a curation status of 'curation' when prior version was :action_required", js: true do
        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'action_required')
        @resource.reload

        sign_in(@author)
        click_link 'My Datasets'
        within(:css, '#user_submitted') do
          click_button 'Update'
        end
        update_dataset
        @resource.reload

        expect(@resource.current_curation_status).to eql('curation')
      end

      it "has a curation status of 'submitted' when prior version was :withdrawn", js: true do
        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'withdrawn')
        @resource.reload

        sign_in(@author)
        click_link 'My Datasets'
        within(:css, '#user_submitted') do
          click_button 'Update'
        end
        update_dataset
        @resource.reload

        expect(@resource.current_curation_status).to eql('submitted')
      end

      context :published_or_embargoed do

        before(:each) do
          ActionMailer::Base.deliveries = []
          mock_datacite!
          mock_stripe!
        end

        it "has a curation status of 'submitted' when prior version was :embargoed", js: true do
          create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'embargoed')
          @resource.reload

          sign_in(@author)
          click_link 'My Datasets'
          within(:css, '#user_submitted') do
            click_button 'Update'
          end
          update_dataset
          @resource.reload

          expect(@resource.current_curation_status).to eql('submitted')
        end

        it "has a curation status of 'submitted' when prior version was :published", js: true do
          create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'published')
          @resource.reload

          sign_in(@author)
          click_link 'My Datasets'
          within(:css, '#user_submitted') do
            click_button 'Update'
          end
          update_dataset
          @resource.reload

          expect(@resource.current_curation_status).to eql('submitted')
        end

      end

    end

  end

  def update_dataset(curator: false)
    # Add a value to the dataset, submit it and then mock a successful submission
    navigate_to_metadata
    description_divider = find('h2', text: 'Data Description')
    description_divider.click
    doi = 'https://doi.org/10.5061/dryad.888gm50'
    mock_good_doi_resolution(doi: doi)
    fill_in 'related_identifier[related_identifier]', with: doi
    # Submit the changes
    navigate_to_review
    fill_in('user_comment', with: Faker::Lorem.sentence) if curator
    click_button 'Submit'
    @resource = StashEngine::Resource.last
    mock_successfull_merritt_submission!(@resource)
  end

end
