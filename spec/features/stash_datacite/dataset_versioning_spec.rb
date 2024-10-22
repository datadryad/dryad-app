require 'rails_helper'
RSpec.feature 'DatasetVersioning', type: :feature do

  include MerrittHelper
  include DatasetHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::DataFile
  include Mocks::Aws

  before(:each) do
    mock_repository!
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
      it 'should display the proper info on the My datasets page', js: true, no_submit: true do
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
      it 'displays the proper information on the My datasets page', js: true do
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

      it 'has the correct statuses', js: true do
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

        it 'displays the proper information on the Admin pages', js: true do
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

  describe :new_version do
    before(:each) do
      # needed to set the user to system user.  Not migrated as part of tests for some reason
      StashEngine::User.create(id: 0, first_name: 'Dryad', last_name: 'System') unless StashEngine::User.where(id: 0).first
      ActionMailer::Base.deliveries = []
      Timecop.travel(Time.now.utc - 5.minutes)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, identifier: @identifier, user_id: @author.id,
                                                tenant_id: @author.tenant_id, accepted_agreement: true)
      create(:description, resource: @resource, description_type: 'technicalinfo')
      create(:data_file, resource: @resource)
      Timecop.return
    end

    context :by_curator do
      it "is submitted, has 'curation' status, and correct admin page info", js: true do
        create(:curation_activity, user: @curator, resource_id: @resource.id, status: 'curation')
        @resource.reload

        sign_in(@curator)
        find('.c-header_nav-button', text: 'Datasets').click
        visit stash_url_helpers.admin_dashboard_path

        # Edit the Dataset as an admin
        click_button 'Edit dataset'
        expect(page).to have_text("You are editing #{@author.name}'s dataset.")
        update_dataset(curator: true)
        @resource.reload

        expect(@resource.submitted?).to eql(true)
        expect(@resource.current_curation_status).to eql('curation')

        # added a curation note to the record
        expect(@resource.curation_activities.where(status: 'in_progress').last.note).to include(@resource.edit_histories.last.user_comment)

        visit stash_url_helpers.admin_dashboard_path

        within(:css, 'tbody tr') do
          # Make sure the appropriate buttons are available
          expect(page).to have_css('button[title="Edit dataset"]')
          expect(page).to have_css('button[aria-label="Update status"]')

          # Make sure the right text is shown
          expect(page).to have_link(@resource.title)
          expect(page).to have_text('Curation')
          @resource.authors.each do |author|
            expect(page).to have_text(author.author_last_name)
          end
          expect(page).to have_text(@curator.name.to_s)
          expect(page).to have_text(@resource.identifier.identifier)
        end

        within(:css, 'tbody tr') do
          find('a[aria-label="Activity log"]').click
        end

        expect(page).to have_text(@resource.identifier)

        # it has the user comment when they clicked to submit and end in-progress edit
        expect(page).to have_text(@resource.edit_histories.last.user_comment)

        expect(page).to have_text('Curation')
        expect(page).to have_text('Dryad System')
        expect(page).to have_text('System set back to curation')
      end
    end

    context :by_author do
      before(:each, js: true) do
        ActionMailer::Base.deliveries = []
        sign_in(@author)
        click_link 'My datasets'
        within(:css, '#user_processing') do
          find('button[name="update"]').click
        end
        update_dataset
        @resource.reload
      end

      it "is 'submitted' without a curator", js: true do
        expect(@resource.submitted?).to eql(true)
        expect(@resource.current_curation_status).to eql('submitted')
        expect(@resource.current_editor_id).to eq(@author.id)
      end

      # TODO: This is no longer tested the same way... may need to install capybara-email
      xit 'sends out a "submitted" email to the author', js: true do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      it 'displays the proper information on the Admin pages', js: true do
        sign_in(@curator)
        find('.c-header_nav-button', text: 'Datasets').click

        visit stash_url_helpers.admin_dashboard_path

        within(:css, 'tbody tr') do
          # Make sure the appropriate buttons are available
          # Make sure the right text is shown
          expect(page).to have_link(@resource.title)
          expect(page).to have_text('Submitted')
          @resource.authors.each do |author|
            expect(page).to have_text(author.author_last_name)
          end
          expect(page).not_to have_text(@curator.name_last_first)
          expect(page).to have_text(@resource.identifier.identifier)
        end

        within(:css, 'tbody tr') do
          find('a[aria-label="Activity log"]').click
        end

        expect(page).to have_text(@resource.identifier.identifier)

        expect(page).to have_text('Submitted')
        expect(page).to have_text(@author.name)
      end

    end

    context :after_ppr_and_curation do
      it 'does not go to ppr when prior version was curated', js: true do
        @resource.update(hold_for_peer_review: true)
        @resource.update(current_editor_id: @curator.id)
        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'curation')
        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'action_required')
        @resource.reload
        Timecop.travel(Time.now.utc + 1.minute)
        sign_in(@author)
        click_link 'My datasets'
        within(:css, "form[action=\"/stash/metadata_entry_pages/new_version?resource_id=#{@resource.id}\"]") do
          find('button[name="update"]').click
        end
        update_dataset
        @resource.reload
        expect(@resource.current_curation_status).to eql('submitted')
        expect(@resource.current_editor_id).to eql(@curator.id)
        Timecop.return
      end
    end

    context :after_curation do
      before(:each) do
        # needed to set the user to system user.  Not migrated as part of tests for some reason
        StashEngine::User.create(id: 0, first_name: 'Dryad', last_name: 'System') unless StashEngine::User.where(id: 0).first
        @resource.update(current_editor_id: @curator.id)
        create(:curation_activity, user: @curator, resource_id: @resource.id, status: 'curation')
        @resource.reload
      end

      it 'has an assigned curator when prior version was :action_required', js: true do
        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'action_required')
        @resource.reload

        sign_in(@author)
        click_link 'My datasets'
        within(:css, '#user_in-progress') do
          find('button[name="update"]').click
        end
        update_dataset
        @resource.reload

        expect(@resource.current_curation_status).to eql('submitted')
        expect(@resource.current_editor_id).to eql(@curator.id)
      end

      it 'has an assigned curator when prior version was :withdrawn', js: true do
        create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'withdrawn')
        @resource.reload

        sign_in(@author)
        click_link 'My datasets'
        within(:css, '#user_withdrawn') do
          find('button[name="update"]').click
        end
        update_dataset
        @resource.reload

        expect(@resource.current_curation_status).to eql('submitted')
        expect(@resource.current_editor_id).to eql(@curator.id)
      end

      it 'is automatically published with simple changes', js: true do
        create(:curation_activity, :published, user: @curator, resource: @resource)
        sign_in(@author)
        click_link 'My datasets'
        within(:css, "form[action=\"/stash/metadata_entry_pages/new_version?resource_id=#{@resource.id}\"]") do
          find('button[name="update"]').click
        end
        minor_update
        @resource.reload
        expect(@resource.current_curation_status).to eql('published')
      end

      context :curator_workflow do
        before(:each) do
          ActionMailer::Base.deliveries = []
          mock_datacite!
          mock_stripe!
        end

        it 'has a backup curator when the previous curator is no longer available', js: true do
          curator2 = create(:user, role: 'curator')
          create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'published')
          @resource.reload

          # demote the original curator
          @curator.roles.curator.destroy_all

          sign_in(@author)
          click_link 'My datasets'
          within(:css, '#user_complete') do
            find('button[name="update"]').click
          end
          update_dataset
          @resource.reload

          expect(@resource.current_curation_status).to eql('submitted')
          expect(@resource.current_editor_id).to eql(curator2.id)
        end

        it 'does not use the backup curator when the previous curator is a tenant_curator', js: true do
          @curator.roles.curator.destroy_all
          create(:role, user: @curator, role: 'curator', role_object: @resource.tenant)
          create(:user, role: 'curator') # backup curator
          @resource.update(current_editor_id: @curator.id)
          create(:curation_activity, user_id: @curator.id, resource_id: @resource.id, status: 'published')
          @resource.reload

          sign_in(@author)
          click_link 'My datasets'
          within(:css, '#user_complete') do
            find('button[name="update"]').click
          end
          update_dataset
          @resource.reload

          expect(@resource.current_curation_status).to eql('submitted')
          expect(@resource.current_editor_id).to eql(@curator.id)
        end

      end
    end
  end

  def set_and_submit
    @resource = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
    submit_form
    mock_successfull_merritt_submission!(@resource)
  end

  def create_dataset
    start_new_dataset
    fill_required_fields
    navigate_to_review
    set_and_submit
  end

  def minor_update
    click_button 'Subjects'
    fill_in_keywords
    click_button 'Preview changes'
    click_button 'Support'
    fill_in_funder
    click_button 'Preview changes'
    set_and_submit
  end

  def update_dataset(curator: false)
    # Add a value to the dataset, submit it and then mock a successful submission
    click_button 'Authors'
    all('[id^=instit_affil_]').last.set('test institution')
    page.send_keys(:tab)
    page.has_css?('.use-text-entered')
    all(:css, '.use-text-entered').each { |i| i.set(true) }
    page.send_keys(:tab)
    click_button 'Preview changes'
    click_button 'Subjects'
    fill_in_keywords
    click_button 'Preview changes'
    click_button 'Related works'
    doi = 'https://doi.org/10.5061/dryad.888gm50'
    mock_good_doi_resolution(doi: doi)
    fill_in 'DOI or other URL', with: doi
    page.send_keys(:tab)
    click_button 'Preview changes'
    add_required_data_files
    # Submit the changes
    fill_in('Describe edits made', with: Faker::Lorem.sentence) if curator
    set_and_submit
  end

end
