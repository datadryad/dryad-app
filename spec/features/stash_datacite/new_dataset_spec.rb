require 'rails_helper'
RSpec.feature 'NewDataset', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Salesforce

  before(:each) do
    mock_salesforce!
    mock_solr!
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
      journal = create(:journal, journal_code: 'JTEST', manuscript_number_regex: '.*?(MAN-\d+).*?')
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

    it 'redirects instead of creating a duplicate for a revision' do
      visit '/submit?journalID=JTEST&manu=MAN-001'
      expect(page).to have_content('Dataset submission')
      resource_id = page.current_path.match(%r{submission/(\d+)})[1].to_i

      visit '/submit?journalID=JTEST&manu=MAN-001.R1'
      expect(page).to have_content('Dataset submission')
      expect(page.current_path.match(%r{submission/(\d+)})[1].to_i).to equal(resource_id)
    end
  end

  context :author_functions, js: true do

    before(:each) do
      start_new_dataset
      navigate_to_metadata
    end

    it 'adds an org author' do
      company = Faker::Company.name
      res_id = page.current_path.match(%r{submission/(\d+)})[1].to_i
      click_button 'Authors'
      click_button '+ Add group author'
      fill_in 'Organization or group name', with: company
      page.send_keys(:tab)
      expect(page).not_to have_text('author name is required.')
      auths = StashEngine::Resource.find(res_id).authors
      expect(auths.last.author_org_name).to eq(company)
      expect(auths.last.author_first_name).to be nil
    end

    it 'reorders authors with keyboard' do
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
  end
end
