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
    @author = create(:user, tenant_id: 'dryad')

    ActionMailer::Base.deliveries = []

    # Sign in and create a new dataset
    sign_in(@author)
    visit root_path
    click_link 'My datasets'
    start_new_dataset
    # fill_required_fields # don't need this if we're not checking metadata and just files
  end

  describe 'Review files' do
    before(:each) do
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
      @file1 = create_data_file(resource_id: @resource_id, url: Faker::Internet.url, status_code: 200)
      @file2 = create_software_file(resource_id: @resource_id, url: Faker::Internet.url, status_code: 200)
      sleep 1
    end

    # TODO: it fails same times. Better to solve this before releasing it again
    xit 'shows right links to edit files' do
      click_link('Review and submit')
      # wait_for_ajax(15)
      expect(page).to have_link('Edit Files', href: '/stash/resources/1/upload', count: 1)
    end
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
      # navigate_to_review
    end

    it 'warns that there are no data files' do
      @resource = StashEngine::Resource.last
      @resource.data_files = []
      @resource.save
      click_link 'Review and submit'

      expect(page).to have_text('Include at least one data file')
    end
  end

  describe 'Warn for README in wrong format' do
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
      @df = @resource.data_files.where(upload_file_name: 'README.md')
      @df.update(upload_file_name: 'README.txt')
    end

    it 'Warns for README.txt instead of Markdown' do
      navigate_to_review

      expect(page).to have_text('README.md missing')
    end
  end

end
