require 'rails_helper'
require 'fileutils'
RSpec.feature 'DatasetQueuing', type: :feature do
  hold_submissions_path = File.expand_path(File.join(Rails.root, '..', 'hold-submissions.txt')).freeze

  include DatasetHelper
  include Mocks::Datacite
  include Mocks::CurationActivity
  include Mocks::RSolr
  include Mocks::Stripe
  include Mocks::Salesforce

  before(:each) do
    FileUtils.rm_f(hold_submissions_path)
    # for this we don't want to mock the whole repository, but just the actual submission to that happens in
    # the queue, Stash::Repo::SubmissionJob.do_submit!
    mock_solr!
    mock_datacite_gen!
    mock_stripe!
    mock_salesforce!
    neuter_curation_callbacks!
    @curator = create(:user, tenant_id: 'dryad')
    create(:role, user: @curator, role: 'admin', role_object: @curator.tenant)
    @superuser = create(:user, role: 'superuser')
    @document_list = []
  end

  after(:each) do
    FileUtils.rm_f(hold_submissions_path)
  end

  describe :submitting_quickly do

    before(:each, js: true) do
      ActionMailer::Base.deliveries = []
      # Sign in and create a new dataset
      sign_in(@superuser)
      visit root_path
      find('button', text: 'Datasets').click
      page.has_css?('.c-header__nav-submenu')
      click_link 'My datasets'
      3.times do
        start_new_dataset
        fill_required_fields
        navigate_to_review
        check 'agree_to_license'
        check 'agree_to_tos'
        check 'agree_to_payment'
        click_button 'submit_dataset'
      end
      @resource = StashEngine::Resource.where(user: @superuser).last
    end

    xit 'should show queuing', js: true do
      visit '/submission_queue'
      wait_for_ajax(15)
      expect(page).to have_content(/[01] are currently processing from this server/)
      expect(page).to have_content(/[23] queued on this server/)
    end

  end
end
