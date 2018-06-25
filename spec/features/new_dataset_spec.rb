require 'features_helper'
require 'byebug'

describe 'new dataset' do
  attr_reader :start_new_dataset

  before(:each) do
    log_in!
    @start_new_dataset = first(:link_or_button, 'Start New Dataset')
    expect(start_new_dataset).not_to be_nil
  end

  describe 'Start New Dataset' do
    before(:each) do
      start_new_dataset.click
    end

    it 'starts a new dataset' do
      expect(page).to have_content('Describe Your Dataset')

      # ##############################
      # Title

      title = find_blank_field_id('title')
      fill_in title, with: 'Of a peculiar Lead-Ore of Germany, and the Use thereof'

      # ##############################
      # Author

      author_first_name = find_field_id('author[author_first_name]')
      fill_in author_first_name, with: 'Robert'
      author_last_name = find_field_id('author[author_last_name]')
      fill_in author_last_name, with: 'Boyle'
      author_affiliation = find_field_id('affiliation') # TODO: make consistent with other author fields
      fill_in author_affiliation, with: 'Hogwarts'
      author_email = find_field_id('author[author_email]')
      fill_in author_email, with: 'boyle@hogwarts.edu'

      # TODO: additional author(s)

      # ##############################
      # Abstract

      # CKEditor is made up of two parts.  A hidden textarea that will contain the value of the input after changes are made
      # and an iFrame where the actual editing takes place (in addition to controls and other things)

      abstract = find_blank_ckeditor_id('description_abstract')

      fill_in_ckeditor abstract, with: <<-ABSTRACT
        There was, not long since, sent hither out of Germany from
        an inquisitive Physician, a List of several Minerals and Earths
        of that Country, and of Hungary, together with a Specimen of each
        of them.
      ABSTRACT

      # ##############################
      # Optional fields

      description_divider = find('summary', text: 'Data Description (optional)')
      description_divider.click

      # ##############################
      # Funding

      # TODO: stop calling this section 'contributor'

      granting_organization = find_blank_field_id('contributor[contributor_name]')
      fill_in granting_organization, with: 'Ministry of Magic'

      award_number = find_blank_field_id('contributor[award_number]')
      fill_in award_number, with: '9¾'

      # ##############################
      # Keywords

      keywords = find_blank_field_id('subject') # TODO: rename field
      fill_in keywords, with: 'Optick Glasses'

      # ##############################
      # Methods

      methods = find_blank_ckeditor_id('description_methods')

      fill_in_ckeditor methods, with: <<-METHODS
        The Stone, according to the Letter of Mr. David Thomas, who sent this account
        to Mr. Boyle, is with Doctor Haughteyn of Salisbury, to whom he also referreth
        for further information.
      METHODS

      # ##############################
      # Usage

      usage_notes = find_blank_ckeditor_id('description_other')

      fill_in_ckeditor usage_notes, with: <<-USAGE
        'Tis found in the Upper Palatinate, at a place called Freyung, and there are
        two sorts of it, whereof one is a kind of Crystalline Stone, and almost all
        good Leads the other not so rich, and more farinaceous.
      USAGE

      # ##############################
      # Related works

      select 'continues', from: 'related_identifier[relation_type]'
      select 'DOI', from: 'related_identifier[related_identifier_type]'
      related_identifier = find_blank_field_id('related_identifier[related_identifier]')
      fill_in related_identifier, with: 'doi:10.1098/rstl.1665.0007' # TODO: is this the preferred format?

    end
  end
end
