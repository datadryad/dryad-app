require 'byebug'
require_relative '../../requests/stash_engine/download_helpers'

RSpec.feature 'Landing', type: :feature, js: true do
  include DatasetHelper
  include DatabaseHelper
  include Mocks::CurationActivity
  include Mocks::Datacite
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

    it 'does not show an unpublished resource' do
      create(:data_file, resource: create(:resource, :submitted, identifier: identifier))
      visit stash_url_helpers.landing_show_path(id: identifier.to_s)
      expect(all('details.c-file-group').count).to eq(1)
    end

    describe 'privileged user' do
      before(:each) { sign_in(curator) }

      it 'shows the privileged user banner' do
        visit stash_url_helpers.landing_show_path(id: identifier.to_s)
        expect(page).to have_text('This is the administrator view of this dataset')
        expect(page).to have_link('Activity log')
        expect(page).to have_link('Public view')
      end

      it 'shows an unpublished resource and hides from public' do
        create(:data_file, resource: create(:resource, :submitted, identifier: identifier))
        visit stash_url_helpers.landing_show_path(id: identifier.to_s)
        expect(all('details.c-file-group').count).to eq(2)

        click_link 'Public view'
        expect(all('details.c-file-group').count).to eq(1)
      end

      it 'shows file alerts and hides from public' do
        file = create(:data_file, resource: resource, download_filename: 'test.csv', upload_file_name: '131232142.csv',
                                  upload_content_type: 'text/csv')
        create(:frictionless_report, generic_file: file, status: 'issues')
        create(:sensitive_data_report, generic_file: file, status: 'issues')
        visit stash_url_helpers.landing_show_path(id: identifier.to_s)
        expect(page).to have_button('Tabular data check alerts')
        expect(page).to have_button('Sensitive data alerts')

        click_button 'Tabular data check alerts'
        expect(page).to have_css('h1', text: 'Tabular data check')
        click_button 'Close dialog'

        click_button 'Sensitive data alerts'
        expect(page).to have_css('h1', text: 'Sensitive data alerts')
        click_button 'Close dialog'

        click_link 'Public view'
        expect(page).not_to have_text('This is the administrator view of this dataset')
        expect(page).not_to have_button('Tabular data check alerts')
        expect(page).not_to have_button('Sensitive data alerts')
      end
    end
  end
end
