require 'rails_helper'
RSpec.feature 'NewDataset', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::CrossrefFunder
  include Mocks::Tenant

  before(:each) do
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
      click_button 'Start New Dataset'
      expect(page).to have_text('My Datasets')
      expect(page).to have_text('Unable to register a DOI at this time. Please contact help@datadryad.org for assistance.')
      expect(StashEngine::Identifier.all.length).to eql(@identifier_count)
      expect(StashEngine::Resource.all.length).to eql(@resource_count)
    end

    it 'successfully mints a new DOI/ARK' do
      click_button 'Start New Dataset'
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
      fill_in 'subject', with: Array.new(3) { Faker::Lorem.word }.join(' ')

      # ##############################
      # Methods
      fill_in_tinymce(field: 'methods', content: Faker::Lorem.paragraph)

      # ##############################
      # Usage
      fill_in_tinymce(field: 'other', content: Faker::Lorem.paragraph)

      # ##############################
      # Related works
      select 'Dataset', from: 'stash_datacite_related_identifier[work_type]'
      fill_in 'stash_datacite_related_identifier[related_identifier]', with: Faker::Pid.doi
    end

    it 'charges user by default', js: true do
      navigate_to_review
      expect(page).to have_text('you will receive an invoice')
    end

    it 'waives the fee when institution is in a fee-waiver country', js: true do
      waiver_country = Faker::Address.country
      waiver_university = Faker::Educator.university
      stub_ror_id_lookup(university: waiver_university, country: waiver_country)
      stub_ror_name_lookup(name: waiver_university)
      allow_any_instance_of(StashDatacite::Affiliation).to receive(:fee_waiver_countries).and_return([waiver_country])

      # ##############################
      # Author w/ affiliation in specific university
      fill_in_author
      page.execute_script("document.getElementsByClassName('js-affil-longname')[0].value = '#{waiver_university}'")
      # a litlte big hacky, but the following fills in the ROR expected of a fee waiver institution's country
      page.execute_script("document.getElementsByClassName('js-affil-id')[0].value = 'https://ror.org/TEST'")
      # first('.ui-menu-item-wrapper').click

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
      stub_ror_id_lookup(university: non_waiver_university, country: non_waiver_country)
      allow_any_instance_of(StashDatacite::Affiliation).to receive(:fee_waiver_countries).and_return(['Waiverlandia'])

      # ##############################
      # Author w/ affiliation in specific university
      fill_in_author
      page.execute_script("document.getElementsByClassName('js-affil-longname')[0].value = '#{non_waiver_university}'")
      # first('.ui-menu-item-wrapper', wait: 5).click

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
