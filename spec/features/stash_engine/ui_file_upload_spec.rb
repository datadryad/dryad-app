require_relative '../../../stash/stash_engine/lib/stash/aws/s3'
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
  include Mocks::Aws

  before(:each) do
    mock_repository!
    mock_solr!
    mock_ror!
    mock_datacite!
    mock_stripe!
    mock_aws!
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

  describe 'Upload Files index' do
    before(:each) do
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
      @file1 = create_data_file(@resource_id)
      @file2 = create_software_file(@resource_id)
      @file2.url = 'http://example.com/example.csv'
      @file2.save
      @file3 = create_supplemental_file(@resource_id)
      click_link('Upload Files') # click on it to refresh the page and show the table with the file
    end

    it 'shows files already uploaded' do
      expect(page).to have_content(@file1.original_filename)
      expect(page).to have_content(@file2.url)
      expect(page).to have_content(@file3.original_filename)
      expect(page).to have_content('New', count: 3)
    end
  end

  describe 'URL manifest files validation' do
    before(:each) do
      @valid_url_manifest = 'http://example.org/funbar.txt'
      @invalid_url_manifest = 'http://example.org/foobar.txt'
      build_stub_requests(@valid_url_manifest, @invalid_url_manifest)
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
    end

    it 'validate data file URL that works' do
      click_button('data_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect_validate_commons
      expect(page).to have_content('Data')

      # and it made it into the database
      fu = @resource.data_files.first
      expect_new_entry_to_have(fu)
    end

    it 'shows problem with bad data file URL' do
      # TODO: test for url already existent
      click_button('data_manifest')
      validate_url_manifest(@invalid_url_manifest)
      expect(page).to have_content('The URL was not found')
    end

    it 'validates software file URL that works' do
      click_button('software_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect_validate_commons
      expect(page).to have_content('Software')

      # and it made it into the database
      fu = @resource.software_files.first
      expect_new_entry_to_have(fu)
    end

    it 'shows problem with bad software URL' do
      click_button('software_manifest')
      validate_url_manifest(@invalid_url_manifest)
      expect(page).to have_content('The URL was not found')
    end

    it 'validate supplemental file URL that works' do
      click_button('supp_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect_validate_commons
      expect(page).to have_content('Supplemental')

      # and it made it into the database
      fu = @resource.supp_files.first
      expect_new_entry_to_have(fu)
    end

    it 'shows problem with bad supplemental file URL' do
      click_button('supp_manifest')
      validate_url_manifest(@invalid_url_manifest)
      expect(page).to have_content('The URL was not found')
    end

  end

  describe 'S3 file uploading' do
    before(:each) do
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
      attach_files

      check('confirm_to_upload')
      click_on('validate_files')
    end

    it 'vanishes Pending file status when start to upload' do
      expect(page).not_to have_content('Pending')
    end

    it 'shows progress bar when start to upload' do
      expect(page.has_css?('progress', count: 3)).to be true
    end

    xit 'removes file from database when click Remove button' do
      # At the time this placeholder test was first written the remove function
      # was working for manifest files and files that are displayed
      # after loading the files already uploaded. The remove function
      # was not working for chosen files from user file system that have
      # just uploaded. TODO: Implement this test!
    end

    xit 'creates S3 entry after upload is complete' do
      # TODO: S3.exists? mock returns true now.
      #  See if it's possible to return something from the Evaporate using S3 mocks
      # TODO: remove raw url for s3 dir name
      result = Stash::Aws::S3.exists?(s3_key: '37fb70ac-1/data/file_example_ODS_10.ods')
      expect(result).to be true
    end

    xit 'achieves 50% of the progress bar after starting to upload' do
      expect(page.find('progress')[:value]).to eql('50')
    end

    xit 'shows "New" label after upload is complete' do
      # TODO: get url from configs and s3 dir name
      stub_request(
        :post, 'https://s3-us-west-2.amazonaws.com/a-test-bucket/37fb70ac-1/data/file_example_ODS_10.ods?uploads'
      )
        .with(headers: { 'Accept' => '*/*' }).to_return(status: 200)
      expect(page).to have_content('New')
    end
  end

  describe 'S3 file uploading mixed with already selected manifest files' do
    before(:each) do
      stub_request(:head, 'http://example.org/funbar.txt')
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': 'text/plain' })

      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
      # Workaround to expose input file type element, removing the class from the input element
      page.execute_script('$("#data").removeClass()')

      attach_file('data', "#{Rails.root}/spec/fixtures/file_example_ODS_10.ods")
      expect(page).to have_content('file_example_ODS_10.ods')
      expect(page).to have_content('Pending', count: 1)

      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/funbar.txt')
      check('confirm_to_validate')
      click_on('validate_files')
      expect(page).to have_content('New')
    end

    it 'only changes table status column to a progress bar if file status is Pending' do
      # TODO: test for table row with other status than 'Pending'
      pending_file_table_row = page.find('td', text: 'Pending')
      check('confirm_to_upload')
      click_on('validate_files')

      within(pending_file_table_row) do
        expect(page.has_css?('progress')).to be true
      end
    end
  end

  describe 'Destroy file uploaded and manifest file' do
    before(:each) do
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
      @file1 = create_data_file(@resource_id)
      @file2 = create_software_file(@resource_id)
      @file2.url = 'http://example.com/example.csv'
      @file2.save
      @file3 = create_supplemental_file(@resource_id)
      click_link('Upload Files') # click on it to refresh the page and show the table with the file
    end

    xit 'calls destroy_manifest when removing New file' do
      # TODO: to solve error:
      #     Failure/Error: raise ActionController::UnknownFormat, message
      #      ActionController::UnknownFormat:
      #        StashEngine::DataFilesController#destroy_manifest is missing a template for this request format and variant.
      #        request.formats: ["text/html"]
      #        request.variant: []
      first('td > a').click
      expect_any_instance_of(StashEngine::GenericFilesController).to receive(:destroy_manifest).and_return('OK')
    end
  end

end
