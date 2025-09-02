require 'rails_helper'
RSpec.feature 'NewDataset', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::CrossrefFunder
  include Mocks::Salesforce

  before(:each) do
    mock_salesforce!
    mock_solr!
    mock_funders!
    @user = create(:user)
    sign_in(@user)
  end

  context :doi_generation do

    before(:each) do
      @identifier_count = StashEngine::Identifier.all.length
      @resource_count = StashEngine::Resource.all.length
    end

    it 'displays an error message if unable to mint a new DOI/ARK' do
      allow(Stash::Doi::DataciteGen).to receive(:new).and_raise(Ezid::Error.new)
      click_button 'Create a new dataset'
      expect(page).to have_text('My datasets')
      expect(page).to have_text('Unable to register a DOI at this time. Please contact help@datadryad.org for assistance.')
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count)
      expect(StashEngine::Resource.all.length).to eql(@resource_count)
    end

    it 'successfully mints a new DOI/ARK', js: true do
      start_new_dataset
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count + 1)
      expect(StashEngine::Resource.all.length).to eql(@resource_count + 1)
    end

  end

  context :from_manuscript_url, js: true do
    before(:each) do
      journal = create(:journal, journal_code: 'JTEST')
      create(:manuscript, manuscript_number: 'MAN-001', journal: journal)
    end

    it 'creates a submission and imports manuscript info' do
      visit '/submit?journalID=JTEST&manu=MAN-001'
      expect(page).to have_content('Dataset submission')
      expect(find_button('Title')).to match_selector('[aria-describedby="step-complete"')
      expect(find_button('Description')).to match_selector('[aria-describedby="step-complete"')
      expect(find_button('Subjects')).to match_selector('[aria-describedby="step-complete"')
    end

    it 'redirects instead of creating a duplicate' do
      visit '/submit?journalID=JTEST&manu=MAN-001'
      expect(page).to have_content('Dataset submission')
      resource_id = page.current_path.match(%r{submission/(\d+)})[1].to_i

      visit '/submit?journalID=JTEST&manu=MAN-001'
      expect(page).to have_content('Dataset submission')
      expect(page.current_path.match(%r{submission/(\d+)})[1].to_i).to equal(resource_id)
    end
  end

  context :form_submission, js: true do

    before(:each) do
      start_new_dataset
      navigate_to_metadata
    end

    it 'reorders authors with keyboard', js: true do
      click_button 'Authors'
      first_author = { first: Faker::Name.unique.first_name, last: Faker::Name.unique.last_name, email: Faker::Internet.email }
      second_author = { first: Faker::Name.unique.first_name, last: Faker::Name.unique.last_name, email: Faker::Internet.email }

      # fill first
      fill_in_author(first_name: first_author[:first], last_name: first_author[:last], email: first_author[:email])

      # fill second
      click_button 'Add author'
      expect(page).to have_content('Second author name is required. Fill in or delete the entry')
      within(:css, '.dd-list-item:not(:first-child)') do
        fill_in_author(first_name: second_author[:first], last_name: second_author[:last], email: second_author[:email])
      end

      el = all(:css, 'button.handle').first
      el.send_keys(:enter)
      el.send_keys(:arrow_down)
      el.send_keys(:enter)

      expect(all(:css, 'input[name=author_first_name]').first.value).to eq(second_author[:first])

      navigate_to_review
      the_html = page.html
      expect(the_html.index(second_author[:last])).to be < the_html.index(first_author[:last]) # because we switched these authors
    end

    it 'charges user by default', js: true do
      click_button 'Agreements'
      expect(page).to have_content("I agree\nto Dryad's payment terms")
    end

    it 'waives the fee when funder has agreed to pay', js: true do
      funder = create(:funder, name: 'Happy Clown School')
      stub_funder_name_lookup(name: 'Happy Clown School')
      fill_required_metadata
      click_button 'Support'
      fill_in_funder(name: 'Happy Clown School', value: funder.id)

      click_button 'Agreements'
      expect(page).to have_text('Payment for this submission is sponsored by Happy Clown School')
    end

    it "doesn't waive the fee when funder isn't paying", js: true do
      fill_required_metadata
      click_button 'Support'
      fill_in_funder(name: 'Wiring Harness Solutions', value: '12XU')

      click_button 'Agreements'
      expect(page).not_to have_text('Payment for this submission is sponsored by')
    end
  end
end
