require 'rails_helper'
RSpec.feature 'NewCollection', type: :feature do

  include CollectionHelper
  include Mocks::RSolr
  include Mocks::CrossrefFunder
  include Mocks::Tenant
  include Mocks::Salesforce

  before(:each) do
    mock_salesforce!
    mock_solr!
    mock_funders!
    mock_tenant!
    @user = create(:user, role: 'curator')
    sign_in(@user)
  end

  context :doi_generation do
    before(:each) do
      @identifier_count = StashEngine::Identifier.all.length
      @resource_count = StashEngine::Resource.all.length
    end

    it 'displays an error message if unable to mint a new DOI/ARK' do
      allow(Stash::Doi::IdGen).to receive(:make_instance).and_raise(Ezid::Error.new)
      visit('/stash/resources/new?collection')
      expect(page).to have_text('My datasets')
      expect(page).to have_text('Unable to register a DOI at this time. Please contact help@datadryad.org for assistance.')
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count)
      expect(StashEngine::Resource.all.length).to eql(@resource_count)
    end

    it 'successfully mints a new DOI/ARK', js: true do
      start_new_collection
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count + 1)
      expect(StashEngine::Resource.all.length).to eql(@resource_count + 1)
    end
  end

  context :form_submission, js: true do

    before(:each) do
      create_datasets
      start_new_collection
    end

    it 'does not have files, readme, or description section', js: true do
      expect(page).not_to have_content('Prepare README')
      expect(page).not_to have_content('Upload files')
      expect(page).not_to have_content('Data description')
      expect(page).not_to have_content('Methods')
    end

    it 'fills in submission form', js: true do

      # subjects
      fill_in 'fos_subjects', with: 'Agricultural biotechnology'

      # ##############################
      # Title
      fill_in 'title', with: Faker::Lorem.sentence

      # ##############################
      # Author
      fill_in_author

      # TODO: additional author(s)

      # ##############################
      # Abstract
      fill_in_tinymce(field: 'abstract', content: Faker::Lorem.paragraph)

      # ##############################
      # Funding
      find_field('Granting organization').set(Faker::Company.name)
      find_field('Award number').set(Faker::Number.number(digits: 5))

      # ##############################
      # Keywords
      fill_in 'keyword_ac', with: Array.new(3) { Faker::Lorem.word }.join(' ')

      # ##############################
      # Autocomplete checkboxes
      page.send_keys(:tab)
      page.has_css?('.use-text-entered')
      all(:css, '.use-text-entered').each { |i| i.set(true) }

      # ##############################
      # Related works
      fill_in_collection
    end

    it 'does not charge user by default', js: true do
      navigate_to_review
      expect(page).not_to have_text('you will receive an invoice')
    end
  end

  context :requirements_not_met do
    it 'should disable submit button', js: true do
      start_new_collection
      navigate_to_review
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).to be_disabled
    end

  end

  context :requirements_met, js: true do

    before(:each) do
      create_datasets
      start_new_collection
      fill_required_fields
      navigate_to_review
      agree_to_everything
    end

    it 'shows collected datasets', js: true do
      expect(page).to have_text('Collected datasets')
      expect(page).to have_selector('.collection-section li', count: 3)
    end

    it 'submit button should be enabled', js: true do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).not_to be_disabled
    end

    it 'submits', js: true do
      submit = find_button('submit_dataset', disabled: :all)
      submit.click
      expect(page).to have_content(StashEngine::Resource.last.title)
      expect(page).to have_content('submitted with DOI')
    end

  end

  context :edit_link do
    it 'opens a page with an edit link and redirects when complete', js: true do
      create_datasets
      @identifier = create(:identifier)
      @identifier.edit_code = Faker::Number.number(digits: 5)
      @identifier.save
      @res = create(:resource, identifier: @identifier)
      create(:resource_type_collection, resource: @res)
      # Edit link for the above collection, including a returnURL that should redirect to a documentation page
      visit "/stash/edit/#{@identifier.identifier}/#{@identifier.edit_code}?returnURL=%2Fstash%2Fsubmission_process"
      all('[id^=instit_affil_]').last.set('test institution')
      page.send_keys(:tab)
      page.has_css?('.use-text-entered')
      all(:css, '.use-text-entered').each { |i| i.set(true) }
      fill_in_keywords
      fill_in_collection
      navigate_to_review
      agree_to_everything
      fill_in 'user_comment', with: Faker::Lorem.sentence
      submit = find_button('submit_dataset', disabled: :all)
      submit.click
      expect(page.current_path).to eq('/stash/submission_process')
    end
  end
end
