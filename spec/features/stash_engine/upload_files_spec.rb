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
  include Mocks::Stripe
  include Mocks::Aws

  before(:each) do
    mock_repository!
    mock_solr!
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
      @file2.update(url: 'http://example.com/example.csv')
      @file3 = create_supplemental_file(@resource_id)
      click_link('Upload Files') # to refresh the page
    end

    it 'shows correct introductory text' do
      expect(page).to have_content('Upload your files')
      expect(page.text).to have_content(
        'You may upload data via two mechanisms: directly from your computer, or from a URL on an external server'
      )
      expect(page.text).to have_content(
        'You will have the opportunity to choose a separate license for your software on the review page.'
      )
      expect(page).to have_link('Zenodo', href: 'https://zenodo.org')
      expect(find_link('Zenodo')[:target]).to eq('_blank')
    end

    it 'shows correct Upload Type boxes example texts' do
      expect(page).to have_content('e.g., csv, fasta')
      expect(page).to have_content('e.g., code packages, scripts')
      expect(page).to have_content('e.g., figures, supporting tables')
    end

    it 'shows files already uploaded' do
      expect(page).to have_content(@file1.upload_file_name)
      expect(page).to have_content(@file2.url)
      expect(page).to have_content(@file3.upload_file_name)
      expect(page).to have_content('Uploaded', count: 3)
    end

    it 'shows the right navigation buttons at the bottom' do
      expect(page). to have_content('Back to Describe Dataset')
      expect(page). to have_content('Proceed to Review')
    end

    it 'shows only files with status different of "deleted"' do
      @file4 = create_data_file(@resource_id)
      @file4.update(original_filename: 'file_deleted.txt', file_state: 'deleted')
      click_link('Upload Files') # click on it to refresh the page and show the table with the file

      expect(page).to_not have_content(@file4.original_filename)
    end

    it 'shows sanitized file names' do
      @file = create_data_file(@resource_id)
      @file.update(
        original_filename: '\u0000 ssh*authorized?keys.csv',
        upload_file_name: '_u0000_ssh_authorized_keys.csv'
      )
      @manifest_file = create_software_file(@resource_id)
      @manifest_file.update(
        original_filename: 'new example*2.com',
        upload_file_name: 'new_example2.com',
        url: 'http://example.com/new%20example*2.com'
      )
      click_link('Upload Files') # to refresh the page
      expect(page).to have_content('_u0000_ssh_authorized_keys.csv')
      expect(page).to have_content('new_example2')
    end
  end

  describe 'Select files to upload' do
    before(:each) do
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
      click_link('Upload Files') # click on it to refresh the page and show the table with the file
      attach_files
    end

    it 'shows files selected with "Pending" status' do
      within(page.find('tr', text: 'file_10.ods')) do
        expect(page).to have_content('Data')
      end
      within(page.find('tr', text: 'file_100.ods')) do
        expect(page).to have_content('Software')
      end
      within(page.find('tr', text: 'file_1000.ods')) do
        expect(page).to have_content('Supp')
      end
      expect(page).to have_content('Pending', count: 3)
    end

    it 'does not allow to select new FILE already in the table and of the same upload type' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { left: 0 }
      )
      expect(page).to have_content('file_10.ods', count: 1)
      expect(page).to have_content('A file of the same type is already in the table, and was not added.')
    end

    it 'does not allow to select new FILES already in the table and of the same upload type' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/funbar.txt", make_visible: { left: 0 }
      )
      attach_file(
        'data',
        %W[#{Rails.root}/spec/fixtures/stash_engine/funbar.txt
           #{Rails.root}/spec/fixtures/stash_engine/file_10.ods],
        make_visible: { left: 0 }
      )
      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)
      expect(page).to have_content(/^\bfile_10.ods\b/, count: 1)
      expect(page).to have_content('Some files of the same type are already in the table, and were not added.')
    end

    it 'allows to select new files already in the table and are not of the same upload type' do
      attach_file(
        'software',
        "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { left: 0 }
      )
      expect(page).to have_content('file_10.ods', count: 2)
    end

    xit 'sanitizes file name' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/crazy*chars?are(crazy)", make_visible: { left: 0 }
      )
      expect(page).to have_content('crazy_chars_are(crazy)')
    end
  end

  describe 'URL manifest files validation' do
    before(:each) do
      @file_name1 = 'funbar.txt'
      @valid_url_manifest = "http://example.org/#{@file_name1}"
      @file_name2 = 'foobar.txt'
      @invalid_url_manifest = "http://example.org/#{@file_name2}"
      build_valid_stub_request(@valid_url_manifest)
      build_invalid_stub_request(@invalid_url_manifest)
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
    end

    it 'validates data file URL that works' do
      click_button('data_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect_validate_commons
      expect(page).to have_content('Data')

      # and it made it into the database
      fu = @resource.data_files.first
      expect_new_entry_to_have(fu)
    end

    it 'shows problem with bad data file URL' do
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

    it 'validates supplemental file URL that works' do
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

    it 'validates file URL equal to other file URL from other upload types' do
      @manifest = create_software_file(@resource_id)
      @manifest.update(url: @valid_url_manifest, upload_file_name: @file_name1)

      click_button('data_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect(page).to have_content(/^\b#{@file_name1}\b/, count: 2)
    end

    it 'correctly blocks adding same files when there are excess of new lines between the URL lines' do
      click_button('data_manifest')
      @file_name2 = 'funbar_2.txt'
      @valid_url_manifest2 = "http://example.org/#{@file_name2}"
      build_valid_stub_request(@valid_url_manifest2)
      validate_url_manifest("#{@valid_url_manifest}\n#{@valid_url_manifest2}")

      click_button('data_manifest')
      validate_url_manifest("\n#{@valid_url_manifest}\n\n#{@valid_url_manifest2}\n\n")

      expect(page).to have_content(/^\b#{@file_name1}\b/, count: 1)
      expect(page).to have_content(/^\b#{@file_name2}\b/, count: 1)
      expect(page).to have_content('Some files of the same type are already in the table, and were not added.')
    end

    it 'shows only non-deleted files after validating URLs' do
      @manifest_deleted = create_data_file(@resource_id)
      @manifest_deleted.update(
        url: 'http://example.org/example_data_file.csv', file_state: 'deleted'
      )

      click_button('data_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect_validate_commons
      expect(page).not_to have_content(@manifest_deleted.original_filename)
    end

    it 'shows sanitized file names and escaped URls' do
      @url_manifest = 'http://example.org/my%20file*name.txt'
      stub_request(:head, @url_manifest)
        .with(
          headers: {
            'Accept' => '*/*'
          }
        )
        .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': 'text/plain' })

      click_button('data_manifest')
      validate_url_manifest(@url_manifest)

      expect(page).to have_content('my_filename.txt')
      expect(page).to have_content('http://example.org/my%20file*name.txt')
    end

    it 'shows cut url if url\'s length is big' do
      @big_url = 'https://path_to/a_big_url_that_is_to_test_cutting_url_with_ellipsis.txt'
      build_valid_stub_request(@big_url)
      click_button('data_manifest')
      validate_url_manifest(@big_url)

      expect(page).to have_content('https://path_to/a_big_url_that..._cutting_url_with_ellipsis.txt')
    end

    it 'shows uncut url if url\' lenght is short' do
      @short_url = 'https://path_to/short_url.txt'
      build_valid_stub_request(@short_url)
      click_button('data_manifest')
      validate_url_manifest(@short_url)

      expect(page).to have_content('https://path_to/short_url.txt')
    end

    # Solve the problem of disappearing spinner right after the axios request
    xit 'shows a spinner while validating urls' do
      click_button('data_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect(page).to have_content('img.spinner')
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

    it 'shows empty progress bar if file has 0 size' do
      # Remove already attached files
      first(:button, 'Remove').click
      first(:button, 'Remove').click
      first(:button, 'Remove').click

      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/empty_file.txt", make_visible: { left: 0 })
      check('confirm_to_upload')
      click_on('validate_files')

      expect(page.has_css?('progress[value]')).to be true
      expect(find('progress')['value']).to eq('0')
    end

    it 'disallows navigation away with pending uploads' do
      click_on('Proceed to Review')
      sleep 0.5
      expect(page).to have_text('please click "Upload pending files"')
    end

    xit 'removes file from database when click Remove button' do
      # At the time this placeholder test was first written the remove function
      # was working for manifest files and files that are displayed
      # after loading the files already uploaded. The remove function
      # was not working for chosen files from user file system that have
      # just uploaded. TODO: Implement this test!
    end

    xit 'does not remove line from Files table if failed calling ajax to remove the file' do
      # TODO: mock axios?
    end

    xit 'removes line from Files table if successfuly calling ajax to remove the file' do
      # TODO: mock axios?
    end

    # TODO: skiping until intermitently capybara tests been solved
    xit 'removes warning messages after clicking in Remove link' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { left: 0 }
      )
      # the message for already added file is displayed

      first(:button, 'Remove').click
      expect(page).not_to have_content('A file of the same type is already in the table, and was not added.')
    end

    xit 'shows spinner when calling ajax to remove the file' do
      # TODO: mock axios?
    end

    xit 'creates S3 entry after upload is complete' do
      # TODO: S3.exists? mock returns true now.
      #  See if it's possible to return something from the Evaporate using S3 mocks
      # TODO: remove raw url for s3 dir name
      result = Stash::Aws::S3.exists?(s3_key: '37fb70ac-1/data/file_10.ods')
      expect(result).to be true
    end

    xit 'achieves 50% of the progress bar after starting to upload' do
      expect(page.find('progress')[:value]).to eql('50')
    end

    xit 'shows "New" label after upload is complete' do
      # TODO: get url from configs and s3 dir name
      stub_request(
        :post, 'https://s3-us-west-2.amazonaws.com/a-test-bucket/37fb70ac-1/data/file_example_ODS_10.ods?uploads'
      ).with(headers: { 'Accept' => '*/*' }).to_return(status: 200)
      expect(page).to have_content('New')
    end

    xit 'sanitizes file name before save it in database' do
      # TODO: (cacods) to implement when mocking Evaporate javascript library.
    end
  end

  describe 'S3 file uploading mixed with already selected manifest files' do
    before(:each) do
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)

      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { left: 0 }
      )
      expect(page).to have_content('file_10.ods')
      expect(page).to have_content('Pending', count: 1)

      build_valid_stub_request('http://example.org/funbar.txt')
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/funbar.txt')
      click_on('validate_files')
      expect(page).to have_content('Uploaded')
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

    it 'does not allow to select new FILE from file system with the same name of manifest FILE' do
      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/funbar.txt", make_visible: { left: 0 })
      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)
      expect(page).to have_content('A file of the same type is already in the table, and was not added.')
    end

    it 'does not allow to select new FILES from file system with the same name of manifest FILES' do
      first(:button, 'Remove').click

      build_valid_stub_request('http://example.org/file_10.ods')
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/file_10.ods')
      click_on('validate_files')

      attach_file(
        'data',
        %W[#{Rails.root}/spec/fixtures/stash_engine/funbar.txt
           #{Rails.root}/spec/fixtures/stash_engine/file_10.ods], make_visible: { left: 0 }
      )

      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)
      expect(page).to have_content(/^\bfile_10.ods\b/, count: 1)
      expect(page).to have_content('Some files of the same type are already in the table, and were not added.')
    end

    it 'does not allow to add a manifest FILE with the same name of a FILE selected from file system' do
      build_valid_stub_request('http://example.org/file_10.ods')
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/file_10.ods')
      click_on('validate_files')

      expect(page).to have_content(/^\bfile_10.ods\b/, count: 1)
      expect(page).to have_content('A file of the same type is already in the table, and was not added.')
    end

    it 'does not allow to add manifest FILEs with the same name of FILES selected from file system' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_100.ods", make_visible: { left: 0 }
      )

      build_valid_stub_request('http://example.org/file_10.ods')
      build_valid_stub_request('http://example.org/file_100.ods')
      click_button('data_manifest')
      fill_in('location_urls', with: "http://example.org/file_10.ods\nhttp://example.org/file_100.ods")
      click_on('validate_files')

      expect(page).to have_content(/^\bfile_10.ods\b/, count: 1)
      expect(page).to have_content(/^\bfile_100.ods\b/, count: 1)
      expect(page).to have_content('Some files of the same type are already in the table, and were not added.')
    end

    it 'removes warning message when adding new file from file system' do
      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/funbar.txt", make_visible: { left: 0 })
      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)

      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_100.ods", make_visible: { left: 0 }
      )
      expect(page).not_to have_content('A file of the same type is already in the table, and was not added.')
    end

    it 'removes warning message when adding new manifest file' do
      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/funbar.txt", make_visible: { left: 0 })
      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)

      build_valid_stub_request('http://example.org/funbar_2.txt')
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/funbar_2.txt')
      click_on('validate_files')
      expect(page).not_to have_content('A file of the same type is already in the table, and was not added.')
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
      click_link 'Upload Files' # refresh the page to show the table with the file
    end

    xit 'calls destroy_manifest when removing New file' do
      # TODO: to solve error:
      #     Failure/Error: raise ActionController::UnknownFormat, message
      #      ActionController::UnknownFormat:
      #        StashEngine::DataFilesController#destroy_manifest is missing a template for this request format and variant.
      #        request.formats: ["text/html"]
      #        request.variant: []
      first('td > a').click
      expect_any_instance_of(StashEngine::GenericFilesController).to
      receive(:destroy_manifest).and_return('OK')
    end
  end

end
