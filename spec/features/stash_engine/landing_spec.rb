require 'byebug'
require_relative '../../requests/stash_engine/download_helpers'

RSpec.feature 'Landing', type: :feature, js: true do

  include MerrittHelper
  include DatasetHelper
  include DatabaseHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::Counter

  context 'published dataset' do
    let(:resource) { create_basic_dataset! }
    let(:identifier) { resource.identifier }
    let(:curator) { create(:user, role: 'curator') }

    before(:each) do
      neuter_curation_callbacks!
      mock_repository!
      mock_solr!
      mock_datacite!
      mock_salesforce!
      mock_stripe!
      mock_counter!

      create(:curation_activity, :curation, user: curator, resource: resource)
      create(:curation_activity, :published, resource: resource, user: curator)
      @token = create(:download_token, resource: resource, available: Time.new + 5.minutes.to_i)
      create(:counter_stat, identifier_id: resource.identifier_id)
    end

    it 'displays a title with italics, superscript, and subscript' do
      resource.update(title: 'This title test has <em>some</em> <sup>special</sup> <sub>elements</sub>')
      visit stash_url_helpers.landing_show_path(id: identifier.to_s)
      expect(page).to have_css('#display_resource h1 em')
      expect(page).to have_css('#display_resource h1 sup')
      expect(page).to have_css('#display_resource h1 sub')
    end

    it 'displays the author list and expands affiliations' do
      visit stash_url_helpers.landing_show_path(id: identifier.to_s)
      resource.authors.each do |author|
        expect(page).to have_text(author.author_full_name)
      end
      expect(page).to have_button('Author affiliations')
      click_button 'Author affiliations'
      expect(page).to have_content(resource.authors.first.affiliations.first.smart_name)
    end

    it 'displays and expands the included sections' do
      visit stash_url_helpers.landing_show_path(id: identifier.to_s)
      expect(page).to have_text('Abstract')
      expect(page).to have_text(resource.descriptions.type_abstract.first.description)
      expect(page).to have_button('README')
      click_button 'README'
      expect(page).to have_text(resource.descriptions.type_technical_info.first.description)
    end

    it 'displays subjects, contributors, and related works' do
      ri = create(:related_identifier, resource: resource)
      sponsor = create(:contributor, resource: resource, contributor_type: 'sponsor')
      funder = create(:contributor, resource: resource)
      visit stash_url_helpers.landing_show_path(id: identifier.to_s)
      expect(page).to have_content("Research facility: #{sponsor.contributor_name}")
      expect(page).to have_content(resource.subjects.order(subject_scheme: :desc, subject: :asc).map(&:subject).join(' '))
      expect(page).to have_content("#{funder.contributor_name}: #{funder.award_number}")
      expect(page).to have_content(ri.related_identifier)
    end

    it 'shows the share icons, metrics when published' do
      visit stash_url_helpers.landing_show_path(id: identifier.to_s)
      expect(page).to have_text('Share:')
      expect(page).to have_text(/\d* downloads/)
    end
  end
end
