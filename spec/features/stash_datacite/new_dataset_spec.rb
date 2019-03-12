require 'rails_helper'

RSpec.feature 'NewDataset', type: :feature do

  include DatasetHelper
  include Mocks::Ezid

  before(:all) do
    # Start Solr - shutdown is handled globally when all tests have finished
    SolrInstance.instance
  end

  before(:each) do
    mock_minting!
    @user = create(:user)
    sign_in(@user)
    start_new_dataset
  end

  context :form_submission do

    it 'submits if all requirements are met' do
      title = find('#title', visible: false)
      fill_in 'title', with: Faker::Lorem.sentence

      # ##############################
      # Author
      fill_in 'author[author_first_name]', with: Faker::Name.first_name
      fill_in 'author[author_last_name]', with: Faker::Name.last_name
      fill_in 'affiliation', with: Faker::Educator.university
      fill_in 'author[author_email]', with: Faker::Internet.email

      # TODO: additional author(s)

      # ##############################
      # Abstract

      # CKEditor is made up of two parts.  A hidden textarea that will contain the value of the input after changes are made
      # and an iFrame where the actual editing takes place (in addition to controls and other things)
      #abstract = find_blank_ckeditor_id('description_abstract')
      fill_in_ckeditor 'description_abstract', with: Faker::Lorem.paragraph

      # ##############################
      # Optional fields
      description_divider = find('summary', text: 'Data Description (optional)')
      description_divider.click

      # ##############################
      # Funding

      # TODO: stop calling this section 'contributor'
      fill_in 'contributor[contributor_name]', with: Faker::Company.name
      fill_in 'contributor[award_number]', with: Faker::Number.number(5)

      # ##############################
      # Keywords
      fill_in 'subject', with: "#{3.times.map{ Faker::Lorem.word }.join(' ')}"

      # ##############################
      # Methods
      #methods = find_blank_ckeditor_id('description_methods')
      fill_in_ckeditor 'description_methods', with: Faker::Lorem.paragraph

      # ##############################
      # Usage
      #usage_notes = find_blank_ckeditor_id('description_other')
      fill_in_ckeditor 'description_other', with: Faker::Lorem.paragraph

      # ##############################
      # Related works
      select 'continues', from: 'related_identifier[relation_type]'
      select 'DOI', from: 'related_identifier[related_identifier_type]'
      fill_in 'related_identifier[related_identifier]', with: Faker::Pid.doi

    end

  end

end
