require 'rails_helper'

RSpec.feature 'ReviewAndSubmit', type: :feature, js: true do

  include MerrittHelper
  include DatasetHelper
  include DatabaseHelper
  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Stripe
  include Mocks::Aws
  include Mocks::Salesforce
  include AjaxHelper

  before(:each) do
    mock_repository!
    mock_solr!
    mock_datacite!
    mock_salesforce!
    mock_stripe!
    mock_aws!
    ignore_zenodo!
    create(:tenant)
    @author = create(:user, tenant_id: 'dryad')

    ActionMailer::Base.deliveries = []

    # Sign in and create a new dataset
    sign_in(@author)
    visit root_path
    click_link 'My datasets'
    start_new_dataset
  end

  describe 'Warn for no data files' do
    before(:each) do
      ActionMailer::Base.deliveries = []
      # Sign in and create a new dataset
      sign_in(@author)
      visit root_path
      click_link 'My datasets'
      start_new_dataset
      fill_required_fields
    end

    it 'warns that there are no data files' do
      @resource = StashEngine::Resource.last
      @resource.data_files = []
      @resource.reload
      expect(@resource.data_files.blank?).to be_truthy
      refresh
      navigate_to_review
      expect(page).to have_text('Files are required')
    end
  end

  describe 'Warn for README' do
    before(:each) do
      ActionMailer::Base.deliveries = []
      # Sign in and create a new dataset
      sign_in(@author)
      visit root_path
      click_link 'My datasets'
      start_new_dataset
      fill_required_fields
      @resource = @resource = StashEngine::Resource.last
      @resource.identifier.update(created_at: '2022-10-31')
      @resource.descriptions.where(description_type: 'technicalinfo').update(description: nil)
      refresh
    end

    it 'Warns for missing README' do
      navigate_to_review

      expect(page).to have_text('A README is required')
    end
  end

end
