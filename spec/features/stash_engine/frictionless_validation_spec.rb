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
  include AjaxHelper

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
    before(:each) do
      @file = create_generic_file(StashEngine::Resource.last.id)
    end

    it 'shows N/A for non-plain-text tabular data files' do
      @file.update(upload_file_name: 'non_tabular')
      click_link 'Upload Files'

      within('table') do
        expect(page).to have_content('N/A')
      end
    end

    it 'shows "Issues found" if file is plain-text and tabular and there is a report for it' do
      @file.update(upload_content_type: 'text/csv')
      @report = StashEngine::FrictionlessReport.create(report: '[{errors: errors}]', generic_file: @file)
      click_link 'Upload Files'
      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Issues found')
      end
    end

    it 'shows "Passed" if file is plain-text and tabular, there is a report for it but it is empty' do
      # This is a weird case, and must not occur.
      @file.update(upload_content_type: 'text/csv')
      @report = StashEngine::FrictionlessReport.create(report: nil, generic_file: @file)
      click_link 'Upload Files'

      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Passed')
      end
    end

    it 'shows "Passed" if file is plain-text and tabular and there is not a report' do
      @file.update(upload_content_type: 'text/csv')
      click_link 'Upload Files'

      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Passed')
      end
    end
  end

  describe 'Tabular Data Check Validation' do
    before(:each) do
      @upload_type = %w[data software supp].sample
    end
    it 'shows Tabular Data Check column' do
      click_link 'Upload Files'
      attach_file(@upload_type, "#{Rails.root}/spec/fixtures/stash_engine/table.csv", make_visible: { left: 0 })
      check('confirm_to_upload')
      click_on('validate_files')

      expect(page).to have_content('Tabular Data Check')
    end

    # Needs to mock S3 submission via Evaporate
    xit 'shows "N/A" after submitting file to S3 and the file is not plain/text tabular' do
      click_link 'Upload Files'
      attach_file(@upload_type, "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { left: 0 })
      check('confirm_to_upload')
      click_on('validate_files')

      within('table') do
        expect(page).to have_content('N/A')
      end
    end

    # TODO: remove if the column is always there
    xit 'shows column if there are New manifest tabular files' do
      click_link 'Upload Files'
      url = 'http://example.org/table.csv'
      stub_request(:any, url).to_return(
        body: File.new("#{Rails.root}/spec/fixtures/stash_engine/table.csv"), status: 200
      )

      click_button("#{@upload_type}_manifest")
      validate_url_manifest(url)

      expect(page).to have_content('Tabular Data Check')
    end

    it 'shows "Checking..." when a New manifest csv file is submitted' do
      click_link 'Upload Files'

      # file is csv if has csv extension or hasn't csv extension but has text/csv mime type
      url_csv = 'http://example.org/table.csv'
      url_wo_csv = 'http://example.org/table'
      url = [url_csv, url_wo_csv].sample
      mime_type = url == url_csv ? %w[text/csv application/octet-stream].sample : 'text/csv'

      stub_request(:head, url)
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': mime_type })
      click_button("#{@upload_type}_manifest")

      # increases network latency to capture possible vanishing "Checking..." status
      # default latency: 5
      # 100: magic number (it worked first setting 100 first time)
      # throughput: capybara complains if not defined (got from https://selenium-python.readthedocs.io/api.html)
      page.driver.browser.network_conditions = { throughput: 500 * 1024, latency: 100 }

      validate_url_manifest(url)
      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Checking...')
      end
    end

    it 'shows "Passed" when csv file is submitted and passed in frictionless validation' do
      click_link 'Upload Files'
      url = 'http://example.org/table.csv'
      build_valid_stub_request(url)

      click_button("#{@upload_type}_manifest")
      validate_url_manifest(url)
      wait_for_ajax(15)
      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Passed')
      end
    end
  end
end
