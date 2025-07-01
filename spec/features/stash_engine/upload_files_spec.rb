require_relative '../../../lib/stash/aws/s3'
require 'rails_helper'
require 'fileutils'

RSpec.feature 'UploadFiles', type: :feature, js: true do

  include MerrittHelper
  include DatasetHelper
  include DatabaseHelper
  include GenericFilesHelper
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Stripe
  include Mocks::Aws
  include Mocks::Salesforce
  include Mocks::DataFile

  before(:each) do
    mock_solr!
    mock_datacite!
    mock_stripe!
    mock_salesforce!
    mock_aws!
    ignore_zenodo!
    mock_file_content!
    create(:tenant)
    @author = create(:user, tenant_id: 'dryad')

    ActionMailer::Base.deliveries = []

    # Sign in and create a new dataset
    sign_in(@author)
    visit root_path
    click_link 'My datasets'
    start_new_dataset
    @resource_id = page.current_path.match(%r{submission/(\d+)})[1].to_i
    @resource = StashEngine::Resource.find(@resource_id)
  end

  describe 'Upload files index' do
    before(:each) do
      @file1 = create_data_file(@resource_id)
      @file2 = create_software_file(@resource_id)
      @file2.update(url: 'http://example.com/example.csv')
      @file3 = create_supplemental_file(@resource_id)
      @file4 = create_data_file(@resource_id)
      @file4.update(original_filename: 'file_deleted.txt', file_state: 'deleted')
      refresh
      navigate_to_upload
    end

    it 'shows correct introductory text' do
      expect(page).to have_content('Upload files to Dryad')
      expect(page.text).to have_content('Files may be uploaded from your computer')
      expect(page.text).to have_content('Files that require other licensing can be published at Zenodo')
      expect(page).to have_link('Zenodo', href: 'https://zenodo.org')
      expect(find_link('Zenodo', href: 'https://zenodo.org')[:target]).to eq('_blank')

      # 'shows correct Upload Type boxes example texts'
      expect(page).to have_content('e.g., code packages, scripts')
      expect(page).to have_content('e.g., figures, supporting tables')

      # 'shows files already uploaded'
      expect(page).to have_content(@file1.download_filename)
      expect(page).to have_content(@file2.url)
      expect(page).to have_content(@file3.download_filename)
      expect(page.has_css?('i[aria-label="complete"]', count: 3)).to be true

      # 'shows only files with status different of "deleted"'

      expect(page).to_not have_content(@file4.original_filename)
    end

    it 'shows sanitized file names' do
      @file = create_data_file(@resource_id)
      @file.update(
        original_filename: '\u0000 ssh*authorized?keys.csv',
        download_filename: '_u0000_ssh_authorized_keys.csv'
      )
      @manifest_file = create_software_file(@resource_id)
      @manifest_file.update(
        original_filename: 'new example*2.com',
        download_filename: 'new_example2.com',
        url: 'http://example.com/new%20example*2.com'
      )
      refresh
      navigate_to_upload
      expect(page).to have_content('_u0000_ssh_authorized_keys.csv')
      expect(page).to have_content('new_example2')
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
      find('span', text: '+ Add files for simultaneous publication at Zenodo').click
      click_button('software_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect_validate_commons
      expect(page).to have_content('Software')

      # and it made it into the database
      fu = @resource.software_files.first
      expect_new_entry_to_have(fu)
    end

    it 'shows problem with bad software URL' do
      find('span', text: '+ Add files for simultaneous publication at Zenodo').click
      click_button('software_manifest')
      validate_url_manifest(@invalid_url_manifest)
      expect(page).to have_content('The URL was not found')
    end

    it 'validates supplemental file URL that works' do
      find('span', text: '+ Add files for simultaneous publication at Zenodo').click
      click_button('supp_manifest')
      validate_url_manifest(@valid_url_manifest)

      expect_validate_commons
      expect(page).to have_content('Supplemental')

      # and it made it into the database
      fu = @resource.supp_files.first
      expect_new_entry_to_have(fu)
    end

    it 'shows problem with bad supplemental file URL' do
      find('span', text: '+ Add files for simultaneous publication at Zenodo').click
      click_button('supp_manifest')
      validate_url_manifest(@invalid_url_manifest)
      expect(page).to have_content('The URL was not found')
    end

    it 'validates file URL equal to other file URL from other upload types' do
      @manifest = create_software_file(@resource_id)
      @manifest.update(url: @valid_url_manifest, download_filename: @file_name1)

      find('span', text: '+ Add files for simultaneous publication at Zenodo').click
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
      expect(page).to have_content('Files of the same name are already in the table. New files were not added.')
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

      expect(page).to have_content('https://path_to/a_bi...rl_with_ellipsis.txt')
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
      navigate_to_metadata
      navigate_to_upload
      find('span', text: '+ Add files for simultaneous publication at Zenodo').click
      attach_files
      expect(page).to have_content('file_10.ods')
    end

    it 'disallows navigation away with pending uploads' do
      # 'shows progress bar when start to upload'
      expect(page.has_css?('progress', count: 3)).to be true
      expect(page).to have_text('Wait for file uploads to complete before leaving this page')
    end

    it 'shows empty progress bar if file has 0 size' do
      # Remove already attached files
      first(:button, 'Remove file').click
      first(:button, 'Remove file').click
      first(:button, 'Remove file').click

      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/empty_file.txt", make_visible: { opacity: 1 })
      expect(page.has_css?('progress[value]')).to be true
      expect(find('progress')['value']).to eq('0')
    end

    it 'does not allow to select new FILE already in the table and of the same upload type' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { opacity: 1 }
      )
      expect(page).to have_content('file_10.ods', count: 1)
      expect(page).to have_content('A file of the same name is already in the table. The new file was not added.')
    end

    it 'does not allow to select new FILES already in the table and of the same upload type' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/funbar.txt", make_visible: { opacity: 1 }
      )
      attach_file(
        'data',
        %W[#{Rails.root}/spec/fixtures/stash_engine/funbar.txt
           #{Rails.root}/spec/fixtures/stash_engine/file_10.ods],
        make_visible: { opacity: 1 }
      )
      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)
      expect(page).to have_content(/^\bfile_10.ods\b/, count: 1)
      expect(page).to have_content('Files of the same name are already in the table. New files were not added.')
    end

    it 'allows to select new files already in the table and are not of the same upload type' do
      attach_file(
        'software',
        "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { opacity: 1 }
      )
      expect(page).to have_content('file_10.ods', count: 2)
    end

    xit 'sanitizes file name' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/crazy*chars?are(crazy)", make_visible: { opacity: 1 }
      )
      expect(page).to have_content('crazy_chars_are(crazy)')
    end
  end

  describe 'S3 file uploading mixed with already selected manifest files' do
    before(:each) do
      navigate_to_metadata
      navigate_to_upload
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { opacity: 1 }
      )
      expect(page).to have_content('file_10.ods')

      build_valid_stub_request('http://example.org/funbar.txt')
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/funbar.txt')
      click_on('validate_files')
      expect(page.has_css?('i[aria-label="complete"]')).to be true
    end

    it 'does not allow to select new FILE from file system with the same name of manifest FILE' do
      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/funbar.txt", make_visible: { opacity: 1 })
      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)
      expect(page).to have_content('A file of the same name is already in the table. The new file was not added.')
    end

    it 'does not allow to select new FILES from file system with the same name of manifest FILES' do
      first(:button, 'Remove file').click

      build_valid_stub_request('http://example.org/file_10.ods')
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/file_10.ods')
      click_on('validate_files')

      attach_file(
        'data',
        %W[#{Rails.root}/spec/fixtures/stash_engine/funbar.txt
           #{Rails.root}/spec/fixtures/stash_engine/file_10.ods], make_visible: { opacity: 1 }
      )

      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)
      expect(page).to have_content(/^\bfile_10.ods\b/, count: 1)
      expect(page).to have_content('Files of the same name are already in the table. New files were not added.')
    end

    it 'does not allow to add a manifest FILE with the same name of a FILE selected from file system' do
      build_valid_stub_request('http://example.org/file_10.ods')
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/file_10.ods')
      click_on('validate_files')

      expect(page).to have_content(/^\bfile_10.ods\b/, count: 1)
      expect(page).to have_content('A file of the same name is already in the table. The new file was not added.')
    end

    it 'does not allow to add manifest FILEs with the same name of FILES selected from file system' do
      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_100.ods", make_visible: { opacity: 1 }
      )

      build_valid_stub_request('http://example.org/file_10.ods')
      build_valid_stub_request('http://example.org/file_100.ods')
      click_button('data_manifest')
      fill_in('location_urls', with: "http://example.org/file_10.ods\nhttp://example.org/file_100.ods")
      click_on('validate_files')

      expect(page).to have_content(/^\bfile_10.ods\b/, count: 1)
      expect(page).to have_content(/^\bfile_100.ods\b/, count: 1)
      expect(page).to have_content('Files of the same name are already in the table. New files were not added.')
    end

    it 'removes warning message when adding new file from file system' do
      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/funbar.txt", make_visible: { opacity: 1 })
      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)

      attach_file(
        'data',
        "#{Rails.root}/spec/fixtures/stash_engine/file_100.ods", make_visible: { opacity: 1 }
      )
      expect(page).not_to have_content('A file of the same name is already in the table. The new file was not added.')
    end

    it 'removes warning message when adding new manifest file' do
      attach_file('data', "#{Rails.root}/spec/fixtures/stash_engine/funbar.txt", make_visible: { opacity: 1 })
      expect(page).to have_content(/^\bfunbar.txt\b/, count: 1)

      build_valid_stub_request('http://example.org/funbar_2.txt')
      click_button('data_manifest')
      fill_in('location_urls', with: 'http://example.org/funbar_2.txt')
      click_on('validate_files')
      expect(page).not_to have_content('A file of the same name is already in the table. The new file was not added.')
    end
  end
end
