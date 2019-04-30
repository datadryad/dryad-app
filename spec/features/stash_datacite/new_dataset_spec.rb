require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'NewDataset', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Ror

  before(:each) do
    mock_solr!
    mock_ror!
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
      # ##############################
      # Title
      fill_in 'title', with: Faker::Lorem.sentence

      # ##############################
      # Author
      fill_in_author

      # TODO: additional author(s)

      # ##############################
      # Abstract
      abstract = find_blank_ckeditor_id('description_abstract')
      fill_in_ckeditor abstract, with: Faker::Lorem.paragraph

      # ##############################
      # Optional fields
      description_divider = find('summary', text: 'Data Description')
      description_divider.click

      # ##############################
      # Funding

      # TODO: stop calling this section 'contributor'
      fill_in 'contributor[contributor_name]', with: Faker::Company.name
      fill_in 'contributor[award_number]', with: Faker::Number.number(5)

      # ##############################
      # Keywords
      fill_in 'subject', with: Array.new(3) { Faker::Lorem.word }.join(' ')

      # ##############################
      # Methods
      methods = find_blank_ckeditor_id('description_methods')
      fill_in_ckeditor methods, with: Faker::Lorem.paragraph

      # ##############################
      # Usage
      usage_notes = find_blank_ckeditor_id('description_other')
      fill_in_ckeditor usage_notes, with: Faker::Lorem.paragraph

      # ##############################
      # Related works
      select 'continues', from: 'related_identifier[relation_type]'
      select 'DOI', from: 'related_identifier[related_identifier_type]'
      fill_in 'related_identifier[related_identifier]', with: Faker::Pid.doi
    end


    it 'charges user by default', js: true do
      # ##############################
      # Title
      fill_in 'title', with: Faker::Lorem.sentence

      # ##############################
      # Author
      fill_in_author

      # ##############################
      # Abstract
      abstract = find_blank_ckeditor_id('description_abstract')
      fill_in_ckeditor abstract, with: Faker::Lorem.paragraph

      navigate_to_review
      expect(page).to have_text('you will receive an invoice')
    end

    it 'waives the fee when institution is in a fee-waiver country', js: true do
      waiver_country = Faker::Address.country
      # waiver_university = Faker::Educator.university
       waiver_university = 'somesuch univ'
      stub_ror_id_lookup(university: waiver_university, country: waiver_country)
      allow_any_instance_of(StashDatacite::Affiliation).to receive(:fee_waiver_countries).and_return([waiver_country])
      
      # ##############################
      # Title
      fill_in 'title', with: Faker::Lorem.sentence

      # ##############################
      # Author w/ affiliation in specific university
      fill_in_author
      page.execute_script("$('#author_affiliation_long_name').val('#{waiver_university}')")
      page.execute_script("$('#author_affiliation_id').val('1')") 
      page.execute_script("$('#author_affiliation_ror_id').val('https://ror.org/TEST')") 
      fill_in 'author[affiliation][long_name]', with: waiver_university
            
      # ##############################
      # Abstract
      abstract = find_blank_ckeditor_id('description_abstract')
      fill_in_ckeditor abstract, with: Faker::Lorem.paragraph
      
      # ######## test data ################
      affiltest = StashDatacite::Affiliation.create(long_name: 'Bertelsmann Music Group', ror_id: '12345')
      country_list = affiltest.fee_waiver_countries

      tres = StashEngine::Resource.last
      tiden = tres.identifier
      taffil = tiden.submitter_affiliation
#      tiden.latest_resource.authors.first.update('a')

      fill_in_ckeditor abstract, with: "Uni = #{waiver_university}, Country = #{waiver_country}, List = #{country_list}, res = #{tres.id} #{tres.title}, tiden = #{tiden}, taffil = #{taffil.present?}|#{taffil}|#{tiden.latest_resource.title}|#{tiden.latest_resource&.authors&.first.author_full_name}|#{tiden.latest_resource&.authors&.first&.affiliation}|"
      # ######## test data ################

      
      navigate_to_review
      expect(page).to have_text('Payment is not required')
      #expect(page).to have_text('an invoice')
    end

  end

end
# rubocop:enable Metrics/BlockLength
