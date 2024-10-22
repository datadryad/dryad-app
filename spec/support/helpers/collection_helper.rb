module CollectionHelper

  def create_datasets
    3.times do
      data = create(:resource)
      create(:resource_type, resource: data)
    end
  end

  def start_new_collection
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    visit('/stash/resources/new?collection')
    expect(page).to have_content('Collection submission')
  end

  def navigate_to_metadata
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_button 'Next'
    page.find('#checklist-button').click unless page.has_button?('Title/Import')
    click_button 'Title/Import'
    expect(page).to have_content('Is your collection associated with a published article?')
  end

  def navigate_to_review
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_button 'Agreements'
    expect(page).to have_content('Publication')
    agree_to_everything
    click_button 'Preview submission'
    expect(page).to have_content('Collection submission preview')
  end

  def fill_required_fields
    fill_required_metadata
  end

  def fill_required_metadata
    # make sure we're on the right page
    navigate_to_metadata
    within_fieldset('Is your collection associated with a published article?') do
      choose('No')
    end
    expect(page).to have_content('Is your collection associated with a submitted manuscript?')
    within_fieldset('Is your collection associated with a submitted manuscript?') do
      choose('No')
    end
    fill_in 'title', with: Faker::Lorem.sentence(word_count: 5)
    click_button 'Next'
    fill_in_author
    click_button 'Next'
    fill_in_funder
    fill_in_research_domain
    fill_in_keywords
    click_button 'Next'
    page.send_keys(:tab)
    page.has_css?('.use-text-entered')
    all(:css, '.use-text-entered').each { |i| i.set(true) }
    add_required_abstract
    expect(page).to have_content('Please list all the datasets in the collection')
    fill_in_collection
  end

  def add_required_abstract
    # fill_in_tinymce(field: 'abstract', content: Faker::Lorem.paragraph)
    res = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
    ab = res.descriptions.find_by(description_type: 'abstract')
    ab.update(description: Faker::Lorem.paragraph)
    refresh
    expect(page).to have_content('Collection submission')
  end

  def submit_form
    click_button 'Preview submission' if page.has_button?('Preview submission')
    expect(page).to have_content('Collection submission preview')
    click_button 'submit_button'
  end

  def fill_in_keywords
    fill_in 'keyword_ac', with: Faker::Lorem.unique.words(number: 3).join(',')
    page.send_keys(:tab)
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
    refresh
    expect(page).to have_content('Research domain')
    fill_in 'Research domain', with: fos
    page.send_keys(:tab)
  end

  def fill_in_collection
    res = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
    sets = StashEngine::Resource.where.not(id: res.id).limit(3)
    sets.each_with_index do |set, i|
      within(".work-form:nth-of-type(#{i + 1})") do
        fill_in 'DOI or other URL', with: set.identifier_uri
      end
      click_button '+ Add work' unless i == sets.length - 1
    end
  end

  def agree_to_everything
    check 'agreement'
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

end
