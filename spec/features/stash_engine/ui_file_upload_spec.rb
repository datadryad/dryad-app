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

  describe 'URL validation' do
    before(:each) do
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

      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
    end

    it 'validate data file URL that works' do
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/funbar.txt')
      check('confirm_to_validate')
      click_on('validate_files')

      expect(page).to have_content('37.22 KB')
      expect(page).to have_content('funbar.txt')
      expect(page).to have_content('Data')

      # and it made it into the database
      fu = @resource.data_files.first
      expect(fu.upload_file_name).to eq('funbar.txt')
      expect(fu.upload_content_type).to eq('text/plain')
      expect(fu.upload_file_size).to eq(37_221)
    end

    it 'shows problem with bad data file URL' do
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/foobar.txt')
      check('confirm_to_validate')
      click_on('validate_files')
      expect(page).to have_content('The URL was not found')
    end

    it 'validates software file URL that works' do
      click_button('software_manifest')
      fill_in('location_urls', with: 'http://example.org/funbar.txt')
      check('confirm_to_validate')
      click_on('validate_files')

      expect(page).to have_content('37.22 KB')
      expect(page).to have_content('funbar.txt')
      expect(page).to have_content('Software')

      # and it made it into the database
      su = @resource.software_files.first
      expect(su.upload_file_name).to eq('funbar.txt')
      expect(su.upload_content_type).to eq('text/plain')
      expect(su.upload_file_size).to eq(37_221)
    end

    it 'shows problem with bad URL' do
      click_button('software_manifest')
      fill_in('location_urls', with: 'http://example.org/foobar.txt')
      check('confirm_to_validate')
      click_on('validate_files')
      expect(page).to have_content('The URL was not found')
    end
  end

  describe 'S3 file uploading' do
    before(:each) do
      # TODO: remove if it's not necessary
      # stub_request(:head, 'funbar.txt')
      #   .with(
      #     headers: {
      #       'Accept' => '*/*'
      #     }
      #   )
      #   .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': 'text/plain' })

      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
    end

    it 'shows Uploading label when uploading' do
      # Workaround to expose input file type element, removing the class from the input element
      page.execute_script('$("#data").removeClass()')
      attach_file('data', "#{Rails.root}/spec/fixtures/merritt_ark_changing_test.txt", make_visible: true)
      expect(page).to have_content('merritt_ark_changing_test.txt')

      check('confirm_to_upload')
      click_on('validate_files')
      expect(page).to have_content('Uploading...')
    end

    it 'creates S3 entry after upload is complete' do
      # Workaround to expose input file type element, removing the class from the input element
      page.execute_script('$("#data").removeClass()')
      attach_file('data', "#{Rails.root}/spec/fixtures/merritt_ark_changing_test.txt", make_visible: true)

      check('confirm_to_upload')
      click_on('validate_files')

      result = Stash::Aws::S3.exists?(s3_key: '37fb70ac-1/data/merritt_ark_changing_test.txt')
      puts result #DB
      expect(result).to be true
    end
  end

end
