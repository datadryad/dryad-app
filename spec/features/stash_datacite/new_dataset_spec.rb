require 'rails_helper'
RSpec.feature 'NewDataset', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::CrossrefFunder
  include Mocks::Tenant
  include Mocks::Salesforce

  before(:each) do
    mock_salesforce!
    mock_solr!
    mock_funders!
    mock_tenant!
    @user = create(:user)
    sign_in(@user)
  end

  context :doi_generation do

    before(:each) do
      @identifier_count = StashEngine::Identifier.all.length
      @resource_count = StashEngine::Resource.all.length
    end

    it 'displays an error message if unable to mint a new DOI/ARK' do
      allow(Stash::Doi::IdGen).to receive(:make_instance).and_raise(Ezid::Error.new)
      click_button 'Start new dataset'
      expect(page).to have_text('My datasets')
      expect(page).to have_text('Unable to register a DOI at this time. Please contact help@datadryad.org for assistance.')
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count)
      expect(StashEngine::Resource.all.length).to eql(@resource_count)
    end

    it 'successfully mints a new DOI/ARK' do
      click_button 'Start new dataset'
      expect(page).to have_text('Describe Dataset')
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count + 1)
      expect(StashEngine::Resource.all.length).to eql(@resource_count + 1)
    end

  end

  context :form_submission do

    before(:each) do
      start_new_dataset
    end

    it 'submits if all requirements are met', js: true do

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
      # Optional fields
      description_divider = find('h2', text: 'Data Description')
      description_divider.click

      # ##############################
      # Funding
      find_field('Granting Organization').set(Faker::Company.name)
      find_field('Award Number').set(Faker::Number.number(digits: 5))

      # ##############################
      # Keywords
      fill_in 'keyword_ac', with: Array.new(3) { Faker::Lorem.word }.join(' ')

      # ##############################
      # Methods
      fill_in_tinymce(field: 'methods', content: Faker::Lorem.paragraph)

      # ##############################
      # Usage
      fill_in_tinymce(field: 'other', content: Faker::Lorem.paragraph)

      # ##############################
      # Related works
      select 'Dataset', from: 'Work Type'
      fill_in 'Identifier or external url', with: Faker::Pid.doi
    end

    it 'reorders authors with keyboard', js: true do
      fill_in 'title', with: Faker::Lorem.sentence
      first_author = { first: Faker::Name.unique.first_name, last: Faker::Name.unique.last_name, email: Faker::Internet.safe_email }
      second_author = { first: Faker::Name.unique.first_name, last: Faker::Name.unique.last_name, email: Faker::Internet.safe_email }

      # fill first
      fill_in 'author_first_name', with: first_author[:first]
      fill_in 'author_last_name', with: first_author[:last]
      fill_in 'author_email', with: first_author[:email]

      # fill second
      click_on 'Add author'
      expect(page).to have_css('input[name=author_first_name]', count: 2)
      all(:css, 'input[name=author_first_name]')[1].set(second_author[:first])
      all(:css, 'input[name=author_last_name]')[1].set(second_author[:last])
      all(:css, 'input[name=author_email]')[1].set(second_author[:email])

      fill_in_tinymce(field: 'abstract', content: Faker::Lorem.paragraph)
      el = all(:css, 'button.fa-workaround').first
      el.send_keys(:enter)
      el.send_keys(:arrow_down)
      el.send_keys(:enter)

      sleep 1
      expect(all(:css, 'input[name=author_first_name]').first.value).to eq(second_author[:first])

      navigate_to_review
      the_html = page.html
      expect(the_html.index(second_author[:last])).to be < the_html.index(first_author[:last]) # because we switched these authors
    end

    it 'charges user by default', js: true do
      navigate_to_review
      expect(page).to have_text('you will receive an invoice')
    end

    it 'waives the fee when institution is in a fee-waiver country', js: true do
      waiver_country = Faker::Address.country
      waiver_university = Faker::Educator.university
      ror_org = create(:ror_org, name: waiver_university, country: waiver_country)
      allow_any_instance_of(StashDatacite::Affiliation).to receive(:fee_waiver_countries).and_return([waiver_country])

      # ##############################
      # Author w/ affiliation in specific university
      fill_in_author
      fill_in_research_domain
      navigate_to_review

      # Need to set the affiliation directly in the backend, because it's a pain to interact with the autocomplete component
      author = StashEngine::Author.first
      author.affiliation.update(long_name: waiver_university, ror_id: ror_org.ror_id)
      navigate_to_review

      expect(page).to have_text('Payment is not required')
    end

    it 'waives the fee when funder has agreed to pay', js: true do
      # APP_CONFIG.funder_exemptions has the exceptions. Right now, just 'Happy Clown School' in test environment
      stub_funder_name_lookup(name: 'Happy Clown School')
      fill_required_metadata
      fill_in_funder(name: 'Happy Clown School', value: '12XU')

      navigate_to_review
      expect(page).to have_text('Payment for this deposit is sponsored by Happy Clown School')
    end

    it "doesn't waive the fee when funder isn't paying", js: true do
      # APP_CONFIG.funder_exemptions has the exceptions. Right now, just 'Happy Clown School' in test environment
      fill_required_metadata
      fill_in_funder(name: 'Wiring Harness Solutions', value: '12XU')

      navigate_to_review
      expect(page).not_to have_text('Payment for this deposit is sponsored by')
    end

    it 'charges user when institution is not in a fee-waiver country', js: true do
      non_waiver_country = Faker::Address.country
      non_waiver_university = Faker::Educator.university
      ror_org = create(:ror_org, name: non_waiver_university, country: non_waiver_country)
      allow_any_instance_of(StashDatacite::Affiliation).to receive(:fee_waiver_countries).and_return(['Waiverlandia'])

      # ##############################
      # Author w/ affiliation in specific university
      fill_in_author
      navigate_to_review

      # Need to set the affiliation directly in the backend, because it's a pain to interact with the autocomplete component
      author = StashEngine::Author.first
      author.affiliation.update(long_name: non_waiver_university, ror_id: ror_org.ror_id)
      navigate_to_review

      expect(page).to have_text('you will receive an invoice')
    end

    it 'fills in a Field of Science subject', js: true do
      fill_required_metadata
      fill_in 'fos_subjects', with: 'Agricultural biotechnology'
      navigate_to_review
      expect(page).to have_text('Agricultural biotechnology', wait: 5)
    end

    it 'fills in a Field of Science subject that is not official', js: true do
      name = Array.new(3) { Faker::Lorem.word }.join(' ')
      fill_required_metadata
      fill_in 'fos_subjects', with: name
      navigate_to_review
      expect(page).to have_text(name, wait: 5)
    end

    it 'fills in a Field of Science subject and changes it and it keeps the latter', js: true do
      name = Array.new(3) { Faker::Lorem.word }.join(' ')
      fill_required_metadata
      fill_in 'fos_subjects', with: name
      fill_in_funder(name: 'Wiring Harness Solutions', value: '12XU')
      fill_in 'fos_subjects', with: 'Agricultural biotechnology'
      navigate_to_review
      expect(page).to have_text('Agricultural biotechnology', wait: 5)
      expect(page).not_to have_text(name, wait: 5)
    end

  end

end
