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
    visit('/resources/new?collection')
    wait_for_ajax
    wait_for_page_load('Describe collection')
    navigate_to_meta
  end

  def navigate_to_meta
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    click_button 'Next'
    page.find('#checklist-button').click unless page.has_button?('Connect')
    click_button 'Connect'
    expect(page).to have_content('Is your collection associated with a preprint, an article, or a manuscript submitted to a journal?')
  end

  def navigate_to_preview
    # Make sure you switch to the Selenium driver for the test calling this helper method
    # e.g. `it 'should test this amazing thing', js: true do`
    page.find('#checklist-button').click unless page.has_button?('Agreements')
    click_button 'Agreements'
    expect(page).to have_content('Is your collection ready to publish?')
    agree_to_everything
    click_button 'Preview submission'
    expect(page).to have_content('Collection submission preview')
  end

  def fill_required_meta
    navigate_to_meta
    within_fieldset('Is your collection associated with a preprint, an article, or a manuscript submitted to a journal?') do
      choose 'No'
    end
    click_button 'Title'
    fill_in_title
    click_button 'Authors'
    fill_in_author
    click_button 'Description'
    fill_in_abstract
    fill_in_research_domain
    fill_in_keywords
    click_button 'Support'
    check('No funding received')
    click_button 'Related works'
    fill_in_collection
  end

  def submit_collection
    click_button 'Preview submission' if page.has_button?('Preview submission')
    expect(page).to have_content('Collection submission preview')
    click_button 'submit_button'
  end

  def fill_in_collection
    page.find('#checklist-button').click unless page.has_button?('Related works')
    click_button 'Related works'
    expect(page).to have_content('Please list all the datasets in the collection')
    res = StashEngine::Resource.find(page.current_path.match(%r{submission/(\d+)})[1].to_i)
    sets = StashEngine::Resource.where.not(id: res.id).limit(3)
    sets.each_with_index do |set, i|
      within(".work-form:nth-of-type(#{i + 1})") do
        fill_in 'DOI or other URL', with: set.identifier_uri
        page.send_keys(:tab)
      end
      click_button '+ Add work' unless i == sets.length - 1
    end
  end
end
