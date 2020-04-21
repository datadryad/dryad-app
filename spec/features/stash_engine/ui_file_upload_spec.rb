require 'rails_helper'
require 'pry-remote'
require 'fileutils'
# binding.remote_pry
RSpec.feature 'UiFileUpload', type: :feature do

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
    fill_required_fields
  end

  describe :file_uploads do
    before(:each, js: true) do
      navigate_to_upload

      # get resource and clean up uploads directories
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      FileUtils.rm_rf(File.join(StashEngine::Resource.uploads_dir, @resource_id.to_s)) unless @resource_id.blank?
      FileUtils.rm_rf(File.join(StashEngine::Resource.uploads_dir, "#{@resource_id}_sfw")) unless @resource_id.blank?
      @resource = StashEngine::Resource.find(@resource_id)
    end

    it 'uploads a file', js: true do
      page.attach_file(Rails.root.join('spec', 'fixtures', 'http_responses', 'favicon.ico')) do
        page.find('#choose-the-files').click
      end
      expect(page).to have_content('favicon.ico')
      check('confirm_to_upload')
      click_on('upload_all')

      # it shows upload complete
      expect(page).to have_content('Upload complete')

      # it copied the file to the appropriate place on the file system
      expect(File.exist?(File.join(StashEngine::Resource.uploads_dir, @resource_id.to_s, 'favicon.ico'))).to eq(true)

      # it put it in the database
      expect(@resource.file_uploads.first.upload_file_name).to eq('favicon.ico')
    end

    it 'deletes a file', js: true do
      page.attach_file(Rails.root.join('spec', 'fixtures', 'http_responses', 'favicon.ico')) do
        page.find('#choose-the-files').click
      end
      expect(page).to have_content('favicon.ico')
      check('confirm_to_upload')
      click_on('upload_all')

      # it shows upload complete
      expect(page).to have_content('Upload complete')

      click_on('Delete')

      expect(page).to have_content('No files have been uploaded.')

      # it copied the file to the appropriate place on the file system
      expect(File.exist?(File.join(StashEngine::Resource.uploads_dir, @resource_id.to_s, 'favicon.ico'))).to eq(false)

      # it put it in the database
      expect(@resource.file_uploads.count).to eq(0)
    end
  end

  describe :software_uploads do
    before(:each, js: true) do
      navigate_to_software_upload

      # get resource and clean up uploads directories
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      FileUtils.rm_rf(File.join(StashEngine::Resource.uploads_dir, @resource_id.to_s)) unless @resource_id.blank?
      FileUtils.rm_rf(File.join(StashEngine::Resource.uploads_dir, "#{@resource_id}_sfw")) unless @resource_id.blank?
      @resource = StashEngine::Resource.find(@resource_id)
    end

    it 'uploads a file', js: true do
      page.attach_file(Rails.root.join('spec', 'fixtures', 'http_responses', 'favicon.ico')) do
        page.find('#choose-the-files').click
      end
      expect(page).to have_content('favicon.ico')
      check('confirm_to_upload')
      click_on('upload_all')

      # it shows upload complete
      expect(page).to have_content('Upload complete')

      # it copied the file to the appropriate place on the file system
      expect(File.exist?(File.join(StashEngine::Resource.uploads_dir, "#{@resource_id}_sfw", 'favicon.ico'))).to eq(true)

      # it put it in the database
      expect(@resource.software_uploads.first.upload_file_name).to eq('favicon.ico')
    end

    it 'deletes a file', js: true do
      page.attach_file(Rails.root.join('spec', 'fixtures', 'http_responses', 'favicon.ico')) do
        page.find('#choose-the-files').click
      end
      expect(page).to have_content('favicon.ico')
      check('confirm_to_upload')
      click_on('upload_all')

      # it shows upload complete
      expect(page).to have_content('Upload complete')

      click_on('Delete')

      expect(page).to have_content('No files have been uploaded.')

      # it copied the file to the appropriate place on the file system
      expect(File.exist?(File.join(StashEngine::Resource.uploads_dir, "#{@resource_id}_sfw", 'favicon.ico'))).to eq(false)

      # it put it in the database
      expect(@resource.software_uploads.count).to eq(0)
    end
  end
end