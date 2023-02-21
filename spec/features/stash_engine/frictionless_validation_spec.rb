require_relative '../../../lib/stash/aws/s3'
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
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::Aws
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

    # This has been tested with each mime type isolated.
    # When inserting a new mime type, comment this line,
    # run the tests with it only and than,
    # add to the array, increasing the rand argument by one, and uncomment it.
    # This is done to not increase so much the tests for each new tabular type.
    #
    # For instance, when adding ODS do:
    #  @tabular_mime_type = 'application/vnd.oasis.opendocument.spreadsheet'
    # and comment the line below.
    # Run the tests and if the tests pass, delete the line above and uncomment
    # the line below, making the changes related above.
    @tabular_mime_type = %w[
      text/csv
      application/vnd.ms-excel
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/json
    ][rand(4)]
  end

  describe 'Tabular data check Index' do
    before(:each) do
      @file = create(:generic_file,
                     resource_id: StashEngine::Resource.last.id,
                     upload_content_type: @tabular_mime_type,
                     upload_file_size: APP_CONFIG[:frictionless][:size_limit],
                     status_code: 200,
                     file_state: 'created')
    end

    it 'shows nothing For Validation for non-tabular files' do
      @file.update(upload_file_name: 'non_tabular', upload_content_type: 'application/pdf', original_filename: 'non_tabular')
      sleep 1
      click_link 'Upload files'

      within('table') do
        expect(page).not_to have_content('Uploaded Too Large For Validation')
      end
    end

    it 'shows Uploaded Too Large For Validation for tabular files greater than the size limit' do
      @file.update(upload_file_size: APP_CONFIG[:frictionless][:size_limit] + 1, upload_file_name: 'tabular.csv', original_filename: 'tabular.csv')
      sleep 1
      click_link 'Upload files'

      within('table') do
        expect(page).to have_content('Uploaded Too Large For Validation')
      end
    end

    xit 'shows "Alerts" if file is tabular and status is "issues"' do
      @report = StashEngine::FrictionlessReport.create!(
        report: '[{errors: errors}]', generic_file: @file, status: 'issues'
      )
      sleep 1
      click_link 'Upload files'

      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to include('Alerts')
      end
    end

    xit 'shows "Passed" if file is tabular, and the status is "noissues"' do
      @report = StashEngine::FrictionlessReport.create!(generic_file: @file, status: 'noissues')
      sleep 1
      click_link 'Upload files'

      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Passed')
      end
    end

    xit 'shows "Validation Error" if file is plain-text and tabular, and the status is "error"' do
      @report = StashEngine::FrictionlessReport.create!(generic_file: @file, status: 'error')
      sleep 1
      click_link 'Upload files'

      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq("Couldn't Read Tabular Data")
      end
    end
  end

  describe 'Tabular data check Validation' do
    before(:each) do
      @upload_type = %w[data software supp].sample
      click_link 'Upload files'
    end
    # TODO: xit: skipping until intermittently capybara tests been solved or
    #   else forget about and move tests from here to React only tests
    xit 'shows Tabular data check column' do
      attach_file(@upload_type, "#{Rails.root}/spec/fixtures/stash_engine/valid.csv", make_visible: { left: 0 })
      check('confirm_to_upload')
      click_on('validate_files')

      expect(page).to have_content('Tabular data check')
    end

    # xit: Needs to mock S3 submission via Evaporate
    xit 'shows "N/A" after submitting file to S3 and the file is not plain/text tabular' do
      attach_file(@upload_type, "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { left: 0 })
      check('confirm_to_upload')
      click_on('validate_files')

      within('table') do
        expect(page).to have_content('N/A')
      end
    end

    # TODO: xit: remove if the column is always there
    xit 'shows column if there are new manifest tabular files' do
      url = 'http://example.org/valid.csv'
      stub_request(:any, url).to_return(
        body: File.new("#{Rails.root}/spec/fixtures/stash_engine/valid.csv"), status: 200
      )

      click_button("#{@upload_type}_manifest")
      validate_url_manifest(url)

      expect(page).to have_content('Tabular data check')
    end

    # TODO: xit: skipping until intermittently capybara tests been solved or
    #   else forget about and move tests from here to React only tests
    xit 'shows "Checking..." when a new manifest csv file is submitted' do
      # file is csv if has csv extension or hasn't csv extension but has text/csv mime type
      url_csv = 'http://example.org/valid.csv'
      url_wo_csv = 'http://example.org/table'
      url = [url_csv, url_wo_csv].sample
      mime_type = url == url_csv ? %w[text/csv application/octet-stream].sample : 'text/csv'
      build_valid_stub_request(url, mime_type)

      stub_file = File.open(File.expand_path('spec/fixtures/stash_engine/valid.csv'))
      stub_request(:get, url)
        .to_return(body: stub_file, status: 200)
      sleep 1

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

    # TODO: xit: skipping until intermittently capybara tests been solved or
    #   else forget about and move tests from here to React only tests
    xit 'shows "Checking..." for new manifest csv files submitted and "N/A" for new manifest non-csv files' do
      url_csv_1 = 'http://example.org/valid.csv'
      url_csv_2 = 'http://example.org/invalid.csv'
      url_non_csv = 'http://example.org/file_10.ods'
      build_valid_stub_request(url_csv_1, 'text/csv')
      build_valid_stub_request(url_csv_2, 'text/csv')
      build_valid_stub_request(url_non_csv, 'application/ods')

      stub_file1 = File.open(File.expand_path('spec/fixtures/stash_engine/valid.csv'))
      stub_request(:get, url_csv_1)
        .to_return(body: stub_file1, status: 200)
      stub_file2 = File.open(File.expand_path('spec/fixtures/stash_engine/invalid.csv'))
      stub_request(:get, url_csv_2)
        .to_return(body: stub_file2, status: 200)
      stub_file3 = File.open(File.expand_path('spec/fixtures/stash_engine/file_10.ods'))
      stub_request(:get, url_non_csv)
        .to_return(body: stub_file3, status: 200)
      sleep 1

      click_button("#{@upload_type}_manifest")
      page.driver.browser.network_conditions = { throughput: 500 * 1024, latency: 100 }
      validate_url_manifest("#{url_csv_1}\n#{url_csv_2}\n#{url_non_csv}")

      within('table') do
        expect(page).to have_content('Checking...', count: 2)
        expect(page).to have_content('N/A')
      end
    end

    # TODO: xit: skipping until intermittently capybara tests been solved or
    #   else forget about and move tests from here to React only tests
    xit 'shows "Passed" when csv file is submitted and pass in frictionless validation' do
      url = 'http://example.org/valid.csv'
      build_valid_stub_request(url)

      stub_file = File.open(File.expand_path('spec/fixtures/stash_engine/valid.csv'))
      stub_request(:get, url)
        .to_return(body: stub_file, status: 200)
      sleep 1

      click_button("#{@upload_type}_manifest")
      validate_url_manifest(url)
      sleep 5

      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Passed')
      end
    end

    # TODO: xit: skipping until intermittently capybara tests been solved or
    #   else forget about and move tests from here to React only tests
    xit 'shows "Issues found" when csv file is submitted and does not pass in frictionless validation' do
      url = 'http://example.org/invalid.csv'
      build_valid_stub_request(url)

      stub_file = File.open(File.expand_path('spec/fixtures/stash_engine/invalid.csv'))
      stub_request(:get, url)
        .to_return(body: stub_file, status: 200)
      sleep 1

      click_button("#{@upload_type}_manifest")
      validate_url_manifest(url)
      sleep 5

      within(:xpath, '//table/tbody/tr/td[2]') do
        expect(text).to eq('Issues found')
      end
    end

    # TODO: xit: skipping until intermittently capybara tests been solved or
    #   else forget about and move test from here to React only tests
    xit 'shows "Passed" for new manifest csv files submitted and "N/A" for new manifest non-csv files' do
      url_csv_1 = 'http://example.org/valid.csv'
      url_csv_2 = 'http://example.org/valid2.csv'
      url_non_csv = 'http://example.org/file_10.ods'
      build_valid_stub_request(url_csv_1, 'text/csv')
      build_valid_stub_request(url_csv_2, 'text/csv')
      build_valid_stub_request(url_non_csv, 'application/ods')

      stub_file1 = File.open(File.expand_path('spec/fixtures/stash_engine/valid.csv'))
      stub_request(:get, url_csv_1)
        .to_return(body: stub_file1, status: 200)
      stub_file2 = File.open(File.expand_path('spec/fixtures/stash_engine/valid2.csv'))
      stub_request(:get, url_csv_2)
        .to_return(body: stub_file2, status: 200)
      stub_file3 = File.open(File.expand_path('spec/fixtures/stash_engine/file_10.ods'))
      stub_request(:get, url_non_csv)
        .to_return(body: stub_file3, status: 200)
      sleep 1

      click_button("#{@upload_type}_manifest")
      validate_url_manifest("#{url_csv_1}\n#{url_csv_2}\n#{url_non_csv}")
      wait_for_ajax(15)

      within('table') do
        expect(page).to have_content('Passed', count: 2)
        expect(page).to have_content('N/A')
      end
    end
  end
end
