require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'DatasetVersioning', type: :feature do

  include MerrittHelper
  include DatasetHelper
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Datacite
  include Mocks::Stripe

  before(:each) do
    mock_repository!
    mock_solr!
    @curator = create(:user, role: 'admin', tenant_id: 'dryad')
    @author = create(:user, tenant_id: 'dryad')
    @document_list = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  describe :initial_version do

    before(:each, js: true) do
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
        mock_successfull_merritt_submission!(@resource)
      end

      it 'has a resource_state (Merritt status) of "submitted"', js: true do
        expect(@resource.submitted?).to eql(true)
      end

      it 'has a curation status of "submitted"', js: true do
        expect(@resource.current_curation_status).to eql('submitted')
      end

      it 'sent out an email to the author', js: true do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
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
          sign_out
          sign_in(@curator)
          click_link 'Admin'
        end

        it 'displays the proper information on the Admin page', js: true do
          within(:css, '.c-lined-table__row') do
            # Make sure the appropriate buttons are available
            expect(page).not_to have_css('button[title="Edit Dataset"]')
            expect(page).to have_css('button[aria-label="Update status"]')

            # Make sure the right text is shown
            expect(page).to have_link(@resource.title)
            within(:css, "#js-curation-state-#{@resource.id}") do
              expect(page).to have_text('Submitted')
            end
            expect(page).to have_text(@resource.authors.first.author_standard_name)
            expect(page).not_to have_text(@curator.name)
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
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, identifier: @identifier, user_id: @author.id, tenant_id: @author.tenant_id)
    end

    context :by_curator do

      before(:each, js: true) do
        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'curation')
        @resource.reload

        sign_in(@curator)
        click_link 'Admin'
        # Edit the Dataset as an admin
        find('button[title="Edit Dataset"]').click
        expect(page).to have_text("You are editing #{@author.name}'s dataset.", wait: 5)
        update_dataset(curator: true)
        @resource.reload
        click_link 'Admin'
      end

      it 'has a resource_state (Merritt status) of "submitted"', js: true do
        expect(@resource.submitted?).to eql(true)
      end

      it 'has a curation status of "curation"', js: true do
        expect(@resource.current_curation_status).to eql('curation')
      end

      it 'carried over the curation note to the curation_activity record', js: true do
        expect(@resource.current_curation_activity.note.include?(@resource.edit_histories.last.user_comment)).to eql(true)
      end

      it 'did not send out an additional email to the author', js: true do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it 'displays the proper information on the Admin page', js: true do
        within(:css, '.c-lined-table__row') do
          # Make sure the appropriate buttons are available
          expect(page).to have_css('button[title="Edit Dataset"]')
          expect(page).to have_css('button[aria-label="Update status"]')

          # Make sure the right text is shown
          expect(page).to have_link(@resource.title)
          expect(page).to have_text('Curation')
          expect(page).to have_text(@resource.authors.first.author_standard_name)
          expect(page).to have_text(@curator.name)
          expect(page).to have_text(@resource.identifier.identifier)
        end
      end

      it 'displays the proper information on the Activity Log page', js: true do
        within(:css, '.c-lined-table__row') do
          find('button[aria-label="View Activity Log"]').click
        end

        expect(page).to have_text(@resource.identifier)

        within(:css, '.c-lined-table__row:last-child') do
          expect(page).to have_text('Curation')
          expect(page).to have_text(@curator.name)
          expect(page).to have_text(@resource.edit_histories.last.user_comment)
        end
      end

    end

    context :by_author do

      before(:each, js: true) do
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

      it 'did not send out an additional email to the author', js: true do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it 'displays the proper information on the Admin page', js: true do
        sign_out
        sign_in(@curator)
        click_link 'Admin'
        within(:css, '.c-lined-table__row') do
          # Make sure the appropriate buttons are available
          # Make sure the right text is shown
          expect(page).to have_link(@resource.title)
          expect(page).to have_text('Submitted')
          expect(page).to have_text(@resource.authors.first.author_standard_name)
          expect(page).not_to have_text(@curator.name)
          expect(page).to have_text(@resource.identifier.identifier)
        end
      end

      it 'displays the proper information on the Activity Log page', js: true do
        sign_out
        sign_in(@curator)
        click_link 'Admin'

        within(:css, '.c-lined-table__row') do
          find('button[aria-label="View Activity Log"]').click
        end

        expect(page).to have_text(@resource.identifier)

        within(:css, '.c-lined-table__row:last-child') do
          expect(page).to have_text('Submitted')
          expect(page).to have_text(@author.name)
          expect(page).to have_text(@resource.edit_histories.last.user_comment)
        end
      end

    end

    context :by_author_after_curation do

      before(:each) do
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
    find('#location_opener').click
    fill_in 'geo_lat_point', with: 37.43
    fill_in 'geo_lng_point', with: -123.03
    # Submit the changes
    navigate_to_review
    fill_in('user_comment', with: Faker::Lorem.sentence) if curator
    click_button 'Submit'
    @resource = StashEngine::Resource.last
    mock_successfull_merritt_submission!(@resource)
  end

end
# rubocop:enable Metrics/BlockLength
