require 'rails_helper'
require 'fileutils'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'DatasetQueuing', type: :feature do

  HOLD_SUBMISSIONS_PATH = File.expand_path(File.join(Rails.root, '..', 'hold-submissions.txt')).freeze

  # include MerrittHelper
  include DatasetHelper
  include Mocks::Datacite
  # include Mocks::Repository
  include Mocks::SubmissionJob
  include Mocks::RSolr
  include Mocks::Ror
  include Mocks::Stripe
  include AjaxHelper

  before(:each) do
    FileUtils.rm(HOLD_SUBMISSIONS_PATH) if File.exist?(HOLD_SUBMISSIONS_PATH)
    # mock_repository!
    # for this we don't want to mock the whole repository, but just the actual submission to Merritt that happens in
    # the queue, Stash::Merritt::SubmissionJob.do_submit!
    mock_submission_job!
    mock_solr!
    mock_ror!
    mock_datacite!
    mock_stripe!
    @curator = create(:user, role: 'admin', tenant_id: 'dryad')
    @author = create(:user, tenant_id: 'dryad', role: 'superuser')
    @document_list = []
  end

  after(:each) do
    FileUtils.rm(HOLD_SUBMISSIONS_PATH) if File.exist?(HOLD_SUBMISSIONS_PATH)
  end

  describe :submitting_quickly do

    before(:each, js: true) do
      ActionMailer::Base.deliveries = []
      # Sign in and create a new dataset
      sign_in(@author)
      visit root_path
      click_link 'My Datasets'
      3.times do
        start_new_dataset
        fill_required_fields
        navigate_to_review
        check 'agree_to_license'
        check 'agree_to_tos'
        check 'agree_to_payment'
        click_button 'submit_dataset'
      end
      @resource = StashEngine::Resource.where(user: @author).last
    end

    it 'should show queuing', js: true do
      visit '/stash/submission_queue'
      wait_for_ajax(15)
      expect(page).to have_content(/[01] are currently processing from this server/)
      expect(page).to have_content(/[23] queued on this server/)
    end

    it 'should pause transfers', js: true do
      visit '/stash/submission_queue'
      click_button 'graceful_shutdown'
      click_link 'go back to viewing queue updates'
      wait_for_ajax(15)
      expect(page).to have_text('Submissions are being held for shutdown on this server')
    end

    it 'should re-enable transfers', js: true do
      FileUtils.touch(HOLD_SUBMISSIONS_PATH)
      visit '/stash/submission_queue'
      click_button 'graceful_start'
      click_link 'go back to viewing queue updates'
      wait_for_ajax(15)
      expect(page).to have_text('Normal submissions in effect on this server')
    end
  end
end
# rubocop:enable Metrics/BlockLength
