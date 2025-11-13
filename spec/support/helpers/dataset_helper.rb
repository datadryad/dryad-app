module DatasetHelper

  def start_new_dataset
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_button 'Create a new dataset'
    expect(page).to have_content('Dataset submission')
  end

  def navigate_to_metadata
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_button 'Next'
    page.find('#checklist-button').click unless page.has_button?('Connect')
    click_button 'Connect'
    expect(page).to have_content('Is your dataset associated with a preprint, an article, or a manuscript submitted to a journal?')
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
    expect(page).to have_content('Are your files ready to publish')
    agree_to_everything
    click_button 'Preview submission'
    expect(page).to have_content('Dataset submission preview')
  end

  def fill_required_fields
    fill_required_metadata
    click_button 'Support'
    fill_in_funder
    click_button 'Files'
    add_required_data_files
    click_button 'README'
    add_required_readme
  end

  def fill_required_metadata
    # make sure we're on the right page
    navigate_to_metadata
    within_fieldset('Is your dataset associated with a preprint, an article, or a manuscript submitted to a journal?') do
      find(:label, 'No').click
    end
    click_button 'Title'
    fill_in_title
    click_button 'Authors'
    fill_in_affiliation
    expect(find_button('Authors')).to match_selector('[aria-describedby="step-complete"')
    click_button 'Description'
    fill_in_abstract
    fill_in_research_domain
    fill_in_keywords
    expect(find_button('Subjects')).to match_selector('[aria-describedby="step-complete"')
    click_button 'Compliance'
    fill_in_validation
  end

  def fill_in_title(title = Faker::Hipster.sentence(word_count: 6))
    find('[name="title"]').send_keys(title)
    page.send_keys(:tab)
    click_button 'Preview changes' if page.has_button?('Preview changes')
    expect(find_button('Title')).to match_selector('[aria-describedby="step-complete"')
  end

  def fill_in_abstract
    find('[name="abstract"]').send_keys(Faker::Lorem.paragraph)
    page.send_keys(:tab)
    click_button 'Preview changes' if page.has_button?('Preview changes')
    expect(find_button('Description')).to match_selector('[aria-describedby="step-complete"')
  end

  def add_required_data_files
    click_button 'Enter URLs'
    url = 'https://github.com/datadryad/dryad-app/raw/refs/heads/main/spec/fixtures/stash_engine/valid.csv'
    validate_url_manifest(url)
    build_valid_stub_request(url, 'text/csv', 501)
    expect(page).to have_content('valid.csv')
  end

  def add_required_readme
    click_button 'Build a README'
    click_button 'readme-next'
    click_button 'readme-next'
    click_button 'readme-next'
    click_button 'readme-next'
    find('[name="readme_editor"]').send_keys("\nThis is some README content.")
    click_button 'Preview changes' if page.has_button?('Preview changes')
    expect(find_button('README')).to match_selector('[aria-describedby="step-complete"')
  end

  def submit_form
    click_button 'Preview submission' if page.has_button?('Preview submission')
    # page.scroll_to(find('footer'))
    # page.scroll_to(find('#submission-heading'))
    expect(page).to have_content('submission preview')
    expect(page).to have_content('ready to publish?')

    find('[name="submit_button"]').click
    return unless page.has_content?('You must complete payment to submit your dataset')

    find('[name="get_invoice"]').click
    find('[name="submit_invoice"]').click
  end

  def fill_manuscript_info(name:, msid:)
    navigate_to_metadata
    within_fieldset('Is your dataset associated with a preprint, an article, or a manuscript submitted to a journal?') do
      find(:label, 'Yes').click
    end
    expect(page).to have_content('Which would you like to connect?')
    within_fieldset('Which would you like to connect?') do
      find(:label, 'Submitted manuscript').click
    end
    fill_in 'publication_ms', with: name
    fill_in 'msid', with: msid
  end

  def fill_crossref_info(doi:)
    navigate_to_metadata
    find(:label, 'Yes').click
    expect(page).to have_content('Which would you like to connect?')
    within_fieldset('Which would you like to connect?') do
      find(:label, 'Published article').click
    end
    fill_in 'primary_article_doi', with: doi
    page.send_keys(:tab)
  end

  def fill_in_keywords
    fill_in 'keyword_ac', with: 3.times.map { Faker::Creature::Animal.unique.name }.join(',')
    page.send_keys(:tab)
    Faker::Creature::Animal.unique.clear
  end

  def fill_in_author(first_name: Faker::Name.unique.first_name, last_name: Faker::Name.unique.last_name, email: Faker::Internet.email)
    fill_in 'author_first_name', with: first_name
    page.send_keys(:tab)
    expect(page.document).to have_content('All progress saved')
    fill_in 'author_last_name', with: last_name
    page.send_keys(:tab)
    expect(page.document).to have_content('All progress saved')
    fill_in 'author_email', with: email
    page.send_keys(:tab)
    expect(page.document).to have_content('All progress saved')
    fill_in_affiliation
  end

  def fill_in_affiliation
    while page.has_css?('[aria-invalid="true"]')
      fill_in 'Institutional affiliation', with: Faker::Educator.university
      page.send_keys(:tab)
      expect(page).to have_css('.use-text-entered')
      find('.use-text-entered').set(true)
      page.send_keys(:tab)
      sleep 1
    end
  end

  def fill_in_validation
    check 'By checking this box, I confirm that my files are compatible with the CC0 license waiver'
    within_fieldset('hsi_fieldset') do
      find(:label, 'No').click
    end
    click_button 'Preview changes' if page.has_button?('Preview changes')
    expect(find_button('Compliance')).to match_selector('[aria-describedby="step-complete"')
  end

  def fill_in_funder(name: Faker::Company.name, value: Faker::Alphanumeric.alphanumeric(number: 8, min_alpha: 2, min_numeric: 4))
    if page.has_text?('The granting organization is or is part of:')
      within_fieldset('The granting organization is or is part of:') do
        find(:label, 'Other').click
      end
    end
    fill_in 'Granting organization', with: name
    fill_in 'award_number', with: value
    find('.use-text-entered').set(true) if page.has_css?('.use-text-entered')
    click_button 'Preview changes' if page.has_button?('Preview changes')
    expect(find_button('Support')).to match_selector('[aria-describedby="step-complete"')
  end

  def fill_in_research_domain
    fos = 'Biological sciences'
    StashDatacite::Subject.create(subject: fos, subject_scheme: 'fos') # the fos field must exist
    click_button 'Subjects'
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

  def build_valid_stub_request(url, mime_type = 'text/plain', size = 37_221)
    stub_request(:head, url)
      .with(
        headers: {
          'Accept' => '*/*'
        }
      )
      .to_return(status: 200, headers: { 'Content-Length': size, 'Content-Type': mime_type })
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
    expect(fu.download_filename).to eq('funbar.txt')
    expect(fu.upload_content_type).to eq('text/plain')
    expect(fu.upload_file_size).to eq(37_221)
  end

end
