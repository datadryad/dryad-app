require 'rails_helper'

RSpec.feature 'DatasetVersioning', type: :feature do

  include MerrittHelper

  before(:all) do
    # Start Solr - shutdown is handled globally when all tests have finished
    SolrInstance.instance
  end

  before(:each) do
    @tenant = create(:tenant)
    @curator = create(:user, role: 'admin', tenant_id: @tenant.id)
    @author = create(:user, tenant_id: @tenant.id)
  end

  describe :initial_version_pre_submit do

    it 'should display the proper info on the My Datasets page' do
      # Sign in and create a new dataset
      sign_in(@author)
      visit root_path
      start_new_dataset
      fill_required_fields
      navigate_to_review
      @resource = StashEngine::Resource.where(user: @author).last
      visit root_path

      within(:css, '#user_in_progress tr:first-child') do
        expect(page).to have_text(@resource.title)
        expect(page).to have_text('In Progress')
        expect(page).to have_link('Resume')
      end
    end

  end

  describe :initial_version_submitted do

    before(:each) do
      # Sign in and create a new dataset
      sign_in(@author)
      visit root_path
      start_new_dataset
      fill_required_fields
      navigate_to_review
      click_button 'Submit'
      @resource = StashEngine::Resource.where(user: @author).last
    end

    it 'has a resource_state (Merritt status) of "submitted"' do
      mock_successfull_merrit_submission(@resource)
      expect(@resource.submitted?).to eql(true)
    end

    it 'has a curation status of "submitted"' do
      mock_successfull_merrit_submission(@resource)
      expect(@resource.current_curation_status).to eql('submitted')
    end

    it 'sent out an email to the author' do
      expect(StashEngine::UserMailer).to receive(:status_change)
      mock_successfull_merrit_submission(@resource)
    end

    it 'displays the proper information on the My Datasets page' do
      mock_successfull_merrit_submission(@resource)
      visit root_path
      within(:css, '#user_submitted tr:first-child') do
        expect(page).to have_text(@resource.title)
        expect(page).to have_text('Submitted')
        expect(page).to have_link('Update')
      end
    end

    describe :when_viewed_by_curator do

      before(:each) do
        mock_successfull_merrit_submission(@resource)
        sign_out
        sign_in(@curator)
        visit root_path
        click_link 'Admin'
      end

      it 'displays the proper information on the Admin page' do
        within(:css, ".c-lined-table__row:first-child") do
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

      it 'displays the proper information on the Activity Log page' do
        within(:css, '.c-lined-table__row:first-child') do
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

  describe :new_version_by_curator do

    it 'has a resource_state (Merritt status) of "submitted"' do

    end

    it 'has a curation status of "curation"' do

    end

    it 'carried over the curation notes to the curation_activity record' do

    end

    it 'did not send out an email to the author' do

    end

    it 'displays the proper information on the Admin page' do

    end

    it 'displays the proper information on the Activity Log page' do

    end

  end

  describe :new_version_by_author do

    it 'has a resource_state (Merritt status) of "submitted"' do

    end

    it 'has a curation status of "curation"' do

    end

    it 'did not send out an email to the author' do

    end

    it 'displays the proper information on the Admin page' do

    end

    it 'displays the proper information on the Activity Log page' do

    end

  end

  describe :peer_review do

    describe :initial_version do

      it 'has a resource_state (Merritt status) of "submitted"' do

      end

      it 'has a curation status of "peer_review"' do

      end

      it 'sent out an email to the author' do

      end

    end

    describe :version_two do

      it 'has a resource_state (Merritt status) of "submitted"' do

      end

      it 'has a curation status of "submitted"' do

      end

      it 'did not send out an email to the author' do

      end

    end

  end

  it 'resolves to the site "My Datasets" when logged in' do
    sign_in
    visit root_path
    expect(page).to have_text('My Datasets')
  end

  it 'resolves to the "Landing Page" when not logged in' do
    visit root_path
    expect(page).to have_text('Promoting scholarship through open data')
  end

end
