module DatasetHelper

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
    fill_required_metadata
    add_required_data_files
  end

  def fill_required_metadata
    # make sure we're on the right page
    navigate_to_metadata

    fill_in 'title', with: Faker::Lorem.sentence
    fill_in_author
    fill_in_research_domain
    fill_in_funder
    fill_in_tinymce(field: 'abstract', content: Faker::Lorem.paragraph)
  end

  def add_required_data_files
    navigate_to_upload
    resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
    @resource = StashEngine::Resource.find(resource_id)
    create(:data_file, resource: @resource, file_state: 'copied')
    create(:data_file, resource: @resource, file_state: 'copied', upload_file_name: 'README.md')
  end

  def submit_form
    submit = find_button('submit_dataset')
    submit.click
  end

  def fill_manuscript_info(name:, issn:, msid:)
    choose('choose_manuscript')
    page.execute_script("$('#publication').val('#{name}')")
    page.execute_script("$('#publication_issn').val('#{issn}')") # must do to fill hidden field
    page.execute_script("$('#publication_name').val('#{name}')") # must do to fill hidden field
    fill_in 'msid', with: msid
  end

  def fill_crossref_info(name:, doi:)
    choose('choose_published')
    fill_in 'publication', with: name
    fill_in 'primary_article_doi', with: doi
  end

  def fill_in_author
    fill_in 'author_first_name', with: Faker::Name.unique.first_name
    fill_in 'author_last_name', with: Faker::Name.unique.last_name
    fill_in 'author_email', with: Faker::Internet.safe_email
    # just fill in results of name dropdown (react) in hidden field and test this separately
    page.execute_script("document.getElementsByClassName('js-affil-longname')[0].value = '#{Faker::Educator.university}'")
  end

  def fill_in_funder(name: Faker::Company.name, value: Faker::Alphanumeric.alphanumeric(number: 8, min_alpha: 2, min_numeric: 4))
    res = StashEngine::Resource.last
    res.update(contributors: [create(:contributor, contributor_name: name, award_number: value, resource: res)])
  end

  def fill_in_research_domain
    # Should work with:
    #    fill_in 'fos_subjects', with: 'Biological sciences'
    # Or at least:
    #    fos_field = page.find('input.fos-subjects', match: :first)
    #    fos_field.send_keys 'Bio', :down, :down, :tab
    # But Capybara is not cooperating with the datalist, so we will fake it....
    fos = 'Biological sciences'
    StashDatacite::Subject.create(subject: fos, subject_scheme: 'fos') # the fos field must exist in the database to be recognized
    res = StashEngine::Resource.last
    res.subjects << create(:subject, subject: fos, subject_scheme: 'fos')
  end

  def agree_to_everything
    # navigate_to_review  # do we really have to re-navigate each time?
    all(:css, '.js-agrees').each { |i| i.click unless i.checked? } # this does the same if they're present, but doesn't always wait
  end

  def attach_files
    attach_file(
      'data',
      "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { left: 0 }
    )
    attach_file(
      'software',
      "#{Rails.root}/spec/fixtures/stash_engine/file_100.ods", make_visible: { left: 0 }
    )
    attach_file(
      'supp',
      "#{Rails.root}/spec/fixtures/stash_engine/file_1000.ods", make_visible: { left: 0 }
    )
  end

  def build_valid_stub_request(url, mime_type = 'text/plain')
    stub_request(:head, url)
      .with(
        headers: {
          'Accept' => '*/*'
        }
      )
      .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': mime_type })
  end

  def build_invalid_stub_request(url)
    stub_request(:head, url)
      .with(
        headers: {
          'Accept' => '*/*'
        }
      )
      .to_return(status: 404)
  end

  def validate_url_manifest(urls)
    fill_in('location_urls', with: urls)
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
