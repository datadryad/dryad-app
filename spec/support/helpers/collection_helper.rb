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
    navigate_to_metadata
  end

  def navigate_to_metadata
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_link 'Describe collection', wait: 15
    expect(page).to have_content('Collection: Basic information')
  end

  def navigate_to_review
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_link 'Review and submit', wait: 15
    expect(page).to have_content('Review description')
  end

  def fill_required_fields
    fill_required_metadata
  end

  def fill_required_metadata
    # make sure we're on the right page
    navigate_to_metadata
    choose('choose_other')
    fill_in 'title', with: Faker::Lorem.sentence(word_count: 5)
    fill_in_author
    fill_in_research_domain
    fill_in_funder
    page.send_keys(:tab)
    page.has_css?('.use-text-entered')
    all(:css, '.use-text-entered').each { |i| i.set(true) }
    fill_in_tinymce(field: 'abstract', content: Faker::Lorem.paragraph)
    3.times { fill_in_keyword }
    fill_in_collection
  end

  def submit_form
    click_button 'Submit', wait: 5
  end

  def fill_in_keyword(keyword: Faker::Creature::Animal.name)
    fill_in 'keyword_ac', with: keyword
    page.send_keys(:tab)
  end

  def fill_in_author
    fill_in 'author_first_name', with: Faker::Name.unique.first_name
    fill_in 'author_last_name', with: Faker::Name.unique.last_name
    fill_in 'author_email', with: Faker::Internet.email
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

  def fill_in_collection
    res = StashEngine::Resource.last
    sets = StashEngine::Resource.where.not(id: res.id).limit(3)
    sets.each do |set|
      create(:related_identifier, relation_type: 'haspart', work_type: 'dataset', resource_id: res.id,
                                  related_identifier: set.identifier_uri, related_identifier_type: 'doi')

    end
  end

  def agree_to_everything
    # navigate_to_review  # do we really have to re-navigate each time?
    all(:css, '.js-agrees').each { |i| i.click unless i.checked? } # this does the same if they're present, but doesn't always wait
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
