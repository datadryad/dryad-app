module DatasetHelper

  def create_data_file(resource_id)
    StashEngine::DataFile.create(
      {
        resource_id: resource_id,
        upload_file_name: 'example_data_file.csv',
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        file_state: 'created'
      }
    )
  end

  def create_software_file(resource_id)
    StashEngine::SoftwareFile.create(
      {
        resource_id: resource_id,
        upload_file_name: 'example_software_file.csv',
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        file_state: 'created'
      }
    )
  end

  def create_supplemental_file(resource_id)
    StashEngine::SuppFile.create(
      {
        resource_id: resource_id,
        upload_file_name: 'example_supp_file.csv',
        upload_content_type: 'text/plain',
        upload_file_size: 31_726,
        file_state: 'created'
      }
    )
  end

  def start_new_dataset
    click_button 'Start New Dataset'
    expect(page).to have_content('Describe Dataset', wait: 15)
    navigate_to_metadata
  end

  def navigate_to_metadata
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_link 'Describe Dataset'
    expect(page).to have_content('Dataset: Basic Information')
  end

  def navigate_to_software_file
    # Sets this up as a page that can see the software/supp info upload page.
    se_identifier = StashEngine::Identifier.all.first
    StashEngine::InternalDatum.create(identifier_id: se_identifier.id, data_type: 'publicationISSN', value: '1687-7667')
    se_identifier.reload
    navigate_to_upload # so the menus refresh to show newly-allowed tab for special zenodo uploads

    click_link 'Upload Software'
    click_link 'Upload directly'
    expect(page).to have_content('Choose Files')
  end

  def navigate_to_upload
    click_link 'Upload Files'
    expect(page).to have_content('Choose Files', count: 3)
    expect(page).to have_content('Enter URLs', count: 3)
  end

  def navigate_to_review
    click_link 'Review and Submit'
    expect(page).to have_content('Review Description')
  end

  def fill_required_fields
    only_fill_required_fields

    # ##############################
    # LICENSE/PAYMENT AGREEMENTS
    agree_to_everything
  end

  def only_fill_required_fields
    # make sure we're on the right page
    navigate_to_metadata

    # ##############################
    # Title
    fill_in 'title', with: Faker::Lorem.sentence

    # ##############################
    # Author
    fill_in_author

    # TODO: additional author(s)

    # ##############################
    # Abstract
    abstract = find_blank_ckeditor_id('description_abstract')
    fill_in_ckeditor abstract, with: Faker::Lorem.paragraph
  end

  def submit_form
    navigate_to_review
    submit = find_button('submit_dataset', disabled: :all)
    submit.click
  end

  def fill_manuscript_info(name:, issn:, msid:)
    choose('choose_manuscript')
    page.execute_script("$('#internal_datum_publication').val('#{name}')")
    page.execute_script("$('#internal_datum_publication_issn').val('#{issn}')") # must do to fill hidden field for issn
    page.execute_script("$('#internal_datum_publication_name').val('#{name}')") # must do to fill hidden field for issn
    fill_in 'internal_datum[msid]', with: msid
  end

  def fill_crossref_info(name:, doi:)
    choose('choose_published')
    fill_in 'internal_datum[publication]', with: name
    fill_in 'internal_datum[doi]', with: doi
  end

  def fill_in_author
    fill_in 'author[author_first_name]', with: Faker::Name.unique.first_name
    fill_in 'author[author_last_name]', with: Faker::Name.unique.last_name
    fill_in 'author[author_email]', with: Faker::Internet.safe_email
    fill_in 'author[affiliation][long_name]', with: Faker::Educator.university
  end

  def fill_in_funder(name:, value:)
    funder_el = page.find('input.js-funders', match: :first)
    funder_el.fill_in(with: name)
    first('.ui-menu-item-wrapper').click
    award_el = page.find('input.js-award_number', match: :first)
    award_el.fill_in(with: value)
  end

  def agree_to_everything
    navigate_to_review
    find('#agree_to_license').click
    find('#agree_to_tos').click
    find('#agree_to_payment').click
  end

  # rubocop:disable Metrics/AbcSize
  def attach_files
    # Workaround to expose input file type elements
    page.execute_script('$("#data").removeClass()')
    page.execute_script('$("#software").removeClass()')
    page.execute_script('$("#supp").removeClass()')

    attach_file('data', "#{Rails.root}/spec/fixtures/file_example_ODS_10.ods")
    attach_file('software', "#{Rails.root}/spec/fixtures/file_example_ODS_100.ods")
    attach_file('supp', "#{Rails.root}/spec/fixtures/file_example_ODS_1000.ods")
    expect(page).to have_content('file_example_ODS_10.ods')
    expect(page).to have_content('data', count: 1)
    expect(page).to have_content('file_example_ODS_100.ods')
    expect(page).to have_content('software', count: 1)
    expect(page).to have_content('file_example_ODS_1000.ods')
    expect(page).to have_content('supplemental', count: 1)
    expect(page).to have_content('Pending', count: 3)
  end
  # rubocop:enable Metrics/AbcSize

  def build_stub_requests(valid, invalid)
    stub_request(:head, valid)
      .with(
        headers: {
          'Accept' => '*/*'
        }
      )
      .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': 'text/plain' })

    stub_request(:head, invalid)
      .with(
        headers: {
          'Accept' => '*/*'
        }
      )
      .to_return(status: 404)
  end

  def validate_url_manifest(url)
    fill_in('location_urls', with: url)
    check('confirm_to_validate')
    click_on('validate_files')
  end

  def expect_validate_commons
    expect(page).to have_content('37.22 KB')
    expect(page).to have_content('funbar.txt')
  end

  def expect_new_entry_to_have(fu)
    expect(fu.upload_file_name).to eq('funbar.txt')
    expect(fu.upload_content_type).to eq('text/plain')
    expect(fu.upload_file_size).to eq(37_221)
  end

end
