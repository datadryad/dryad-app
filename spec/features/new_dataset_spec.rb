require 'features_helper'

describe 'new dataset' do
  attr_reader :start_new_dataset

  before(:each) do
    visit('/')
    first(:link_or_button, 'Login').click
    @start_new_dataset = first(:link_or_button, 'Start New Dataset')
    expect(start_new_dataset).not_to be_nil
  end

  def find_blank_field(name_or_id)
    field = find_field(name_or_id)
    expect(field.value).to be_blank
    field
  end

  describe 'Start New Dataset' do
    before(:each) do
      start_new_dataset.click
    end

    it 'starts a new dataset' do
      expect(page).to have_content('Describe Your Dataset')

      # ##############################
      # Title

      title = find_blank_field('title')
      fill_in title[:id], with: 'Of a peculiar Lead-Ore of Germany, and the Use thereof'

      # ##############################
      # Author

      author_first_name = find_blank_field('author[author_first_name]')
      fill_in author_first_name[:id], with: 'Robert'
      author_last_name = find_blank_field('author[author_last_name]')
      fill_in author_last_name[:id], with: 'Boyle'
      author_affiliation = find_blank_field('affiliation') # TODO: make consistent with other author fields
      fill_in author_affiliation[:id], with: 'Hogwarts'
      author_email = find_blank_field('author[author_email]')
      fill_in author_email[:id], with: 'boyle@hogwarts.edu'

      # TODO: additional author(s)

      # ##############################
      # Abstract

      abstract = find_blank_field('description_abstract')
      fill_in abstract[:id], with: <<-ABSTRACT
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

      granting_organization = find_blank_field('contributor[contributor_name]')
      fill_in granting_organization[:id], with: 'Ministry of Magic'

      award_number = find_blank_field('contributor[award_number]')
      fill_in award_number[:id], with: '9¾'

      # ##############################
      # Keywords

      keywords = find_blank_field('subject') # TODO: rename field
      fill_in keywords[:id], with: 'Optick Glasses'

      # ##############################
      # Methods

      methods = find_blank_field('description_methods')
      fill_in methods[:id], with: <<-METHODS
        The Stone, according to the Letter of Mr. David Thomas, who sent this account
        to Mr. Boyle, is with Doctor Haughteyn of Salisbury, to whom he also referreth
        for further information.
      METHODS

      # ##############################
      # Usage

      usage_notes = find_blank_field('description_other') # TODO: rename field
      fill_in usage_notes[:id], with: <<-USAGE
        'Tis found in the Upper Palatinate, at a place called Freyung, and there are
        two sorts of it, whereof one is a kind of Crystalline Stone, and almost all
        good Leads the other not so rich, and more farinaceous.
      USAGE

      # ##############################
      # Related works

      select 'continues', from: 'related_identifier[relation_type]'
      select 'DOI', from: 'related_identifier[related_identifier_type]'
      related_identifier = find_blank_field('related_identifier')
      fill_in related_identifier[:id], with: 'doi:10.1098/rstl.1665.0007' # TODO: is this the preferred format?

    end
  end
end
