require 'rails_helper'
RSpec.feature 'DatasetVersioning', type: :feature do

  # copied and xited from dataset versioning—these tests are just too slow!

  include MerrittHelper
  include DatasetHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::DataFile
  include Mocks::Aws

  before(:each) do
    mock_salesforce!
    mock_solr!
    mock_aws!
    mock_datacite_gen!
    mock_stripe!
    ignore_zenodo!
    neuter_curation_callbacks!
    mock_file_content!
    @curator = create(:user, role: 'curator')
    @author = create(:user)
    @document_list = []
  end

  # Combine tests if possible as these take a lot of time!
  describe :initial_version do

    before(:each, js: true) do |test|
      Timecop.travel(Time.now.utc - 5.minutes)
      ActionMailer::Base.deliveries = []
      # Sign in and create a new dataset
      sign_in(@author)
      visit root_path
      click_link 'My datasets'
      start_new_dataset
      fill_required_fields
      navigate_to_review
      @resource = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
      submit_form unless test.metadata.key?(:no_submit)
      Timecop.return
    end

    describe :pre_submit do
      xit 'should display the proper info on the My datasets page', js: true, no_submit: true do
        # part 1
        click_link 'My datasets'

        expect(page).to have_text(@resource.title)
        expect(page).to have_text('In progress')

        # part 2
        click_button 'Resume'
        submit_form

        click_link 'My datasets'
        expect(page).to have_text(@resource.title)
        expect(page).to have_text('Processing')

        # No email
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end

    describe :merritt_submission_error do
      xit 'displays the proper information on the My datasets page', js: true do
        mock_merritt_send!(@resource)
        mock_unsuccessfull_merritt_submission!(@resource)
        click_link 'My datasets'
        within(:css, '#user_processing li:first-child') do
          expect(page).to have_text(@resource.title)
          expect(page).to have_text('Processing')
          expect(page).not_to have_selector('button[name="update"]')
        end
      end
    end

    describe :merritt_submission_success do
      before(:each) do
        ActionMailer::Base.deliveries = []
        mock_merritt_send!(@resource)
        mock_successfull_merritt_submission!(@resource)
      end

      xit 'has the correct statuses', js: true do
        # Merritt status
        expect(@resource.submitted?).to eql(true)
        # curarion status
        expect(@resource.current_curation_status).to eql('submitted')
        # displays the proper information on the My datasets page
        click_link 'My datasets'
        within(:css, '#user_processing li:first-child') do
          expect(page).to have_text(@resource.title)
          expect(page).to have_text('Submitted')
          expect(page).to have_selector('button[name="update"]')
        end
      end

      describe :when_viewed_by_curator do
        before(:each, js: true) do
          sign_in(@curator)
          find('.c-header_nav-button', text: 'Datasets').click
          visit stash_url_helpers.admin_dashboard_path
        end

        xit 'displays the proper information on the Admin pages', js: true do
          # Admin dashboard
          within(:css, 'tbody tr') do
            # Make sure the appropriate buttons are available
            # Curators want to edit everything unless it's in progress, so enjoy
            expect(page).to have_css('button[title="Edit dataset"]')
            expect(page).to have_css('button[aria-label="Update status"]')

            # Make sure the right text is shown
            expect(page).to have_link(@resource.title)
            within(:css, "#curation_activity_#{@resource.id}") do
              expect(page).to have_text('Submitted')
            end
            expect(page).to have_text(@resource.authors.collect(&:author_last_name).join('; '))
            expect(page).not_to have_text(@curator.name_last_first)
            expect(page).to have_text(@resource.identifier.identifier)
          end

          # Activity log
          within(:css, 'tbody tr') do
            find('a[aria-label="Activity log"]').click
          end

          expect(page).to have_text(@resource.identifier)
          expect(page).to have_text('Submitted')
          expect(page).to have_text(@author.name)
        end
      end
    end
  end
end
