require 'rails_helper'
require 'pry-remote'
require 'fileutils'
# binding.remote_pry
RSpec.feature 'UiFileUpload', type: :feature, js: true do

  include MerrittHelper
  include DatasetHelper
  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Ror
  include Mocks::Stripe

  before(:each) do
    mock_repository!
    mock_solr!
    mock_ror!
    mock_datacite!
    mock_stripe!
    ignore_zenodo!
    @author = create(:user, tenant_id: 'dryad')

    ActionMailer::Base.deliveries = []

    # Sign in and create a new dataset
    sign_in(@author)
    visit root_path
    click_link 'My Datasets'
    start_new_dataset
    # fill_required_fields # don't need this if we're not checking metadata and just files
  end

  describe 'normal URL validation' do

    before(:each) do
      navigate_to_upload
      navigate_to_upload_urls

      # get resource and clean up uploads directories
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)

      stub_request(:head, 'http://example.org/funbar.txt')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': 'text/plain' })

      stub_request(:head, 'http://example.org/foobar.txt')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 404)
    end

    it 'validates a URL that works' do
      fill_in('location_urls', with: 'http://example.org/funbar.txt')
      check('confirm_to_validate')
      click_on('validate_files')

      expect(page).to have_content('37.22 kB')
      expect(page).to have_content('funbar.txt')

      # and it made it into the database
      fu = @resource.data_files.first
      expect(fu.upload_file_name).to eq('funbar.txt')
      expect(fu.upload_content_type).to eq('text/plain')
      expect(fu.upload_file_size).to eq(37_221)
    end

    it 'shows problem with bad URL' do
      fill_in('location_urls', with: 'http://example.org/foobar.txt')
      check('confirm_to_validate')
      click_on('validate_files')

      expect(page).to have_content('The URL was not found')

      # and it made it into the database
      fu = @resource.data_files.first
      expect(fu.upload_file_name).to be_nil
      expect(fu.upload_content_type).to be_nil
      expect(fu.upload_file_size).to be_nil
      expect(fu.status_code).to eq(404)
    end
  end

  describe 'software URL validation' do

    before(:each) do
      navigate_to_software_file
      navigate_to_software_file_urls

      # get resource and clean up uploads directories
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)

      stub_request(:head, 'http://example.org/funbar.txt')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': 'text/plain' })

      stub_request(:head, 'http://example.org/foobar.txt')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 404)
    end

    it 'validates a URL that works' do
      fill_in('location_urls', with: 'http://example.org/funbar.txt')
      check('confirm_to_validate')
      click_on('validate_files')

      expect(page).to have_content('37.22 kB')
      expect(page).to have_content('funbar.txt')

      # and it made it into the database
      su = @resource.software_files.first
      expect(su.upload_file_name).to eq('funbar.txt')
      expect(su.upload_content_type).to eq('text/plain')
      expect(su.upload_file_size).to eq(37_221)
    end

    it 'shows problem with bad URL' do
      fill_in('location_urls', with: 'http://example.org/foobar.txt')
      check('confirm_to_validate')
      click_on('validate_files')

      expect(page).to have_content('Describe Dataset')
      expect(page).to have_content('The URL was not found')

      # and it made it into the database
      su = @resource.software_files.first
      expect(su.upload_file_name).to be_nil
      expect(su.upload_content_type).to be_nil
      expect(su.upload_file_size).to be_nil
      expect(su.status_code).to eq(404)
    end
  end
end
