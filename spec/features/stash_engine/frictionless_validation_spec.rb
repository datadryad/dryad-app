require_relative '../../../stash/stash_engine/lib/stash/aws/s3'
require 'rails_helper'
require 'pry-remote'
require 'fileutils'
# binding.remote_pry

RSpec.feature 'UploadFiles', type: :feature, js: true do

  include MerrittHelper
  include DatasetHelper
  include DatabaseHelper
  include GenericFilesHelper
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
  end

  describe 'Tabular Data Check Index' do
    it 'shows N/A for plain-text non-tabular data files' do
      @resource_id = StashEngine::Resource.last.id
      @file = create_data_file(@resource_id)
      @file.update(upload_content_type: 'application/vnd.oasis.opendocument.spreadsheet')
      click_link 'Upload Files'

      within('table') do
        expect(page).to have_content('N/A')
      end
    end

    it 'shows "Issues found" if file is plain-text and tabular and there are a report for it' do
      @file = create_data_file(StashEngine::Resource.last.id)
      @file.update(upload_content_type: 'text/csv')
      @report = StashEngine::FrictionlessReport.create(report: '[{errors: errors}]', generic_file: @file)
      click_link 'Upload Files'
      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Issues found')
      end
    end

    it 'shows empty cell if file is plain-text and tabular and there are not a report for it' do
      @file = create_data_file(StashEngine::Resource.last.id)
      @file.update(upload_content_type: 'text/csv')
      @report = StashEngine::FrictionlessReport.create(report: nil, generic_file: @file)
      click_link 'Upload Files'

      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('')
      end
    end
  end

  describe 'Tabular Data Check Validation' do
    it 'shows Tabular Data Check column' do
      click_link 'Upload Files'
      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/table.csv", make_visible: { left: 0 })
      check('confirm_to_upload')
      click_on('validate_files')

      expect(page).to have_content('Tabular Data Check')
    end

    # Needs to mock S3 submission via Evaporate
    xit 'shows "N/A" after submitting file to S3 and the file is not plain/text tabular' do
      click_link 'Upload Files'
      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { left: 0 })
      check('confirm_to_upload')
      click_on('validate_files')

      within('table') do
        expect(page).to have_content('N/A')
      end
    end

    # TODO: remove if the column is always there
    xit 'displays column if there are New manifest tabular files' do
      click_link 'Upload Files'
      url = 'http://example.org/table.csv'
      stub_request(:any, url).to_return(
        body: File.new("#{Rails.root}/spec/fixtures/stash_engine/table.csv"), status: 200
      )

      click_button('data_manifest')
      validate_url_manifest(url)

      expect(page).to have_content('Tabular Data Check')
    end
  end
end
