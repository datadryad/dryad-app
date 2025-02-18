module DatasetHelper

  def start_new_dataset
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_button 'Start new dataset'
    expect(page).to have_content('Dataset submission')
  end

  def navigate_to_metadata
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_button 'Next'
    page.find('#checklist-button').click unless page.has_button?('Title')
    click_button 'Title'
    expect(page).to have_content('Is your data used in a published article, with a DOI?')
  end

  def navigate_to_readme
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    page.find('#checklist-button').click unless page.has_button?('README')
    click_button 'README'
    expect(page).to have_content('See these example READMES from previous Dryad submissions')
  end

  def navigate_to_upload
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    page.find('#checklist-button').click unless page.has_button?('Files')
    click_button 'Files'
    expect(page).to have_content('Choose files')
    expect(page).to have_content('Enter URLs')
  end

  def navigate_to_review
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    page.find('#checklist-button').click unless page.has_button?('Agreements')
    click_button 'Agreements'
    expect(page).to have_content('Publication of your files')
    agree_to_everything
    click_button 'Preview submission'
    expect(page).to have_content('Dataset submission preview')
  end

  def fill_required_fields
    fill_required_metadata
    add_required_abstract
    add_required_data_files
    add_required_readme
    refresh
  end

  def fill_required_metadata
    # make sure we're on the right page
    navigate_to_metadata
    within_fieldset('Is your data used in a published article, with a DOI?') do
      find(:label, 'No').click
    end
    expect(page).to have_content('Is your data used in a submitted manuscript, with a manuscript number?')
    within_fieldset('Is your data used in a submitted manuscript, with a manuscript number?') do
      find(:label, 'No').click
    end
    fill_in 'title', with: Faker::Lorem.sentence(word_count: 5)
    click_button 'Next'
    fill_in_author
    click_button 'Next'
    fill_in_funder
    fill_in_research_domain
    fill_in_keywords
  end

  def add_required_abstract
    # fill_in_tinymce(field: 'abstract', content: Faker::Lorem.paragraph)
    res = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
    ab = res.descriptions.find_by(description_type: 'abstract')
    ab.update(description: Faker::Lorem.paragraph)
  end

  def add_required_data_files
    res = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
    # file must be copied; since it will not appear in AWS dataset_validations
    create(:data_file, resource: res, file_state: 'copied')
  end

  def add_required_readme
    res = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
    ab = res.descriptions.find_by(description_type: 'technicalinfo')
    ab.update(description: Faker::Lorem.paragraph)
  end

  def submit_form
    click_button 'Preview submission' if page.has_button?('Preview submission')
    click_button 'submit_button'
  end

  def fill_manuscript_info(name:, issn:, msid:)
    navigate_to_metadata
    within_fieldset('Is your data used in a published article, with a DOI?') do
      find(:label, 'No').click
    end
    expect(page).to have_content('Is your data used in a submitted manuscript, with a manuscript number?')
    within_fieldset('Is your data used in a submitted manuscript, with a manuscript number?') do
      find(:label, 'Yes').click
    end
    page.execute_script("$('#publication').val('#{name}')")
    page.execute_script("$('#publication_issn').val('#{issn}')") # must do to fill hidden field
    page.execute_script("$('#publication_name').val('#{name}')") # must do to fill hidden field
    fill_in 'msid', with: msid
  end

  def fill_crossref_info(name:, doi:)
    navigate_to_metadata
    find(:label, 'Yes').click
    fill_in 'publication', with: name
    fill_in 'primary_article_doi', with: doi
    page.send_keys(:tab)
  end

  def fill_in_keywords
    fill_in 'keyword_ac', with: 3.times.map { Faker::Creature::Animal.unique.name }.join(',')
    page.send_keys(:tab)
    Faker::Creature::Animal.unique.clear
  end

  def fill_in_author
    fill_in 'author_first_name', with: Faker::Name.unique.first_name
    fill_in 'author_last_name', with: Faker::Name.unique.last_name
    fill_in 'author_email', with: Faker::Internet.email
    # just fill in results of name dropdown (react) in hidden field and test this separately
    fill_in 'Institutional affiliation', with: Faker::Educator.university
    page.send_keys(:tab)
    page.has_css?('.use-text-entered')
    all(:css, '.use-text-entered').each { |i| i.click unless i.checked? }
  end

  def fill_in_funder(name: Faker::Company.name, value: Faker::Alphanumeric.alphanumeric(number: 8, min_alpha: 2, min_numeric: 4))
    fill_in 'Granting organization', with: name
    fill_in 'award_number', with: value
    page.has_css?('.use-text-entered')
    all(:css, '.use-text-entered').each { |i| i.click unless i.checked? }
  end

  def fill_in_research_domain
    fos = 'Biological sciences'
    StashDatacite::Subject.create(subject: fos, subject_scheme: 'fos') # the fos field must exist
    click_button 'Next'
    expect(page).to have_content('Research domain')
    select(fos, from: 'Research domain')
    page.send_keys(:tab)
  end

  def agree_to_everything
    find('#agreement').click
  end

  def attach_files
    attach_file(
      'data',
      "#{Rails.root}/spec/fixtures/stash_engine/file_10.ods", make_visible: { opacity: 1 }
    )
    attach_file(
      'software',
      "#{Rails.root}/spec/fixtures/stash_engine/file_100.ods", make_visible: { opacity: 1 }
    )
    attach_file(
      'supp',
      "#{Rails.root}/spec/fixtures/stash_engine/file_1000.ods", make_visible: { opacity: 1 }
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
