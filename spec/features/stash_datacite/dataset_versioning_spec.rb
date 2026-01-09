require 'rails_helper'
RSpec.feature 'DatasetVersioning', type: :feature do
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

  describe :new_version do
    before(:each) do
      # needed to set the user to system user.  Not migrated as part of tests for some reason
      StashEngine::User.create(id: 0, first_name: 'Dryad', last_name: 'System') unless StashEngine::User.where(id: 0).first
      ActionMailer::Base.deliveries = []
      Timecop.travel(Time.now.utc - 5.minutes)
      @identifier = create(:identifier)
      @resource = create(:resource, :submitted, identifier: @identifier, user: @author,
                                                tenant_id: @author.tenant_id, accepted_agreement: true)
      create(:description, resource: @resource, description_type: 'technicalinfo')
      create(:description, resource: @resource, description_type: 'hsi_statement', description: nil)
      create(:data_file, resource: @resource)
      @resource.reload
      @resource.identifier.update(last_invoiced_file_size: @resource.total_file_size)
      Timecop.return
    end

    context :by_curator do
      it "is submitted, has 'curation' status, and correct admin page info", js: true do
        CurationService.new(user: @curator, resource_id: @resource.id, status: 'curation').process
        @resource.reload

        sign_in(@curator)
        find('.c-header_nav-button', text: 'Datasets').click
        visit stash_url_helpers.admin_dashboard_path

        # Edit the Dataset as an admin
        within(:css, "#dataset_description_#{@resource.identifier_id}") do
          click_button 'Edit dataset'
        end
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
          expect(page).to have_link(@resource.title&.html_safe)
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

        expect(page).to have_text(@resource.identifier.identifier)
        within(:css, '#activity_log_table > tbody:last-child') do
          find('button[aria-label="Curation activity"]').click
        end
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

        # 'displays the proper information on the Admin pages', js: true do
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
        @resource.update(hold_for_peer_review: true, current_editor_id: @curator.id)
        CurationService.new(user_id: @curator.id, resource_id: @resource.id, status: 'curation').process
        CurationService.new(user_id: @curator.id, resource_id: @resource.id, status: 'action_required').process
        @resource.reload
        Timecop.travel(Time.now.utc + 1.minute)
        sign_in(@author)
        click_link 'My datasets'
        within(:css, "form[action=\"/metadata_entry_pages/new_version?resource_id=#{@resource.id}\"]") do
          find('button[name="update"]').click
        end
        update_dataset
        @resource.reload
        expect(@resource.current_curation_status).to eql('submitted')
        expect(@resource.user_id).to eql(@curator.id)
        Timecop.return
      end
    end

    context :after_curation do
      before(:each) do
        # needed to set the user to system user.  Not migrated as part of tests for some reason
        StashEngine::User.create(id: 0, first_name: 'Dryad', last_name: 'System') unless StashEngine::User.where(id: 0).first
        @resource.update(current_editor_id: @curator.id)
        CurationService.new(user: @curator, resource_id: @resource.id, status: 'curation').process
        @resource.reload
      end

      it 'has an assigned curator when prior version was :action_required', js: true do
        CurationService.new(user_id: @curator.id, resource_id: @resource.id, status: 'action_required').process
        @resource.reload

        sign_in(@author)
        click_link 'My datasets'
        within(:css, '#user_in-progress') do
          find('button[name="update"]').click
        end
        update_dataset
        @resource.reload

        expect(@resource.current_curation_status).to eql('submitted')
        expect(@resource.user_id).to eql(@curator.id)
      end

      it 'has an assigned curator when prior version was :withdrawn', js: true do
        CurationService.new(user_id: @curator.id, resource_id: @resource.id, status: 'withdrawn').process
        @resource.reload

        sign_in(@author)
        click_link 'My datasets'
        within(:css, '#user_withdrawn') do
          find('button[name="update"]').click
        end
        update_dataset
        @resource.reload

        expect(@resource.current_curation_status).to eql('submitted')
        expect(@resource.user_id).to eql(@curator.id)
      end

      it 'is automatically published with simple changes', js: true do
        @resource.check_add_readme_file
        create(:curation_activity, :published, user: @curator, resource: @resource)
        sign_in(@author)
        click_link 'My datasets'
        within(:css, "form[action=\"/metadata_entry_pages/new_version?resource_id=#{@resource.id}\"]") do
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
          create(:curation_activity, :published, user_id: @curator.id, resource_id: @resource.id)
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
          expect(@resource.user_id).to eql(curator2.id)
        end

        it 'does not use the backup curator when the previous curator is a tenant_curator', js: true do
          @curator.roles.curator.destroy_all
          create(:role, user: @curator, role: 'curator', role_object: @resource.tenant)
          create(:user, role: 'curator') # backup curator
          @resource.update(current_editor_id: @curator.id)
          CurationService.new(user_id: @curator.id, resource_id: @resource.id, status: 'published').process
          @resource.reload

          sign_in(@author)
          click_link 'My datasets'
          within(:css, '#user_complete') do
            find('button[name="update"]').click
          end
          update_dataset
          @resource.reload

          expect(@resource.current_curation_status).to eql('submitted')
          expect(@resource.user_id).to eql(@curator.id)
        end

      end
    end
  end

  def set_and_submit
    @resource = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
    submit_form
    @resource.current_state = 'submitted'
    @resource.save
    @resource.reload
  end

  def minor_update
    click_button 'Subjects'
    fill_in_keywords
    click_button 'Preview changes'
    click_button 'Support'
    fill_in_funder
    set_and_submit
  end

  def update_dataset(curator: false)
    # Add a value to the dataset, submit it and then mock a successful submission
    click_button 'Authors'
    all('[id^=instit_affil_]').last.set(Faker::Company.name)
    page.send_keys(:tab)
    find('.use-text-entered').set(true) if page.has_css?('.use-text-entered')
    page.send_keys(:tab)
    click_button 'Preview changes'
    click_button 'Subjects'
    fill_in_keywords
    click_button 'Preview changes'
    click_button 'Related works'
    doi = Faker::Internet.url
    mock_good_doi_resolution(doi: doi)
    fill_in 'DOI or other URL', with: doi
    page.send_keys(:tab)
    click_button 'Preview changes'
    # Submit the changes
    fill_in('Describe edits made', with: Faker::Lorem.sentence) if curator
    set_and_submit
  end

end
