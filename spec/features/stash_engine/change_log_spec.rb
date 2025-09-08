require 'rails_helper'
RSpec.feature 'ChangeLog', type: :feature, js: true do
  include DatasetHelper
  include Mocks::Aws
  include Mocks::Repository
  include Mocks::CurationActivity
  include Mocks::Datacite
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::DataFile

  describe 'display versioning metadata' do
    let(:user) { create(:user) }
    let(:curator) { create(:user, role: 'curator') }

    before(:each) do
      mock_aws!
      mock_solr!
      mock_salesforce!
      mock_stripe!
      mock_repository!
      mock_datacite!
      mock_file_content!
      neuter_curation_callbacks!
      sign_in(user)
      start_new_dataset
      res_id = page.current_path.match(%r{submission/(\d+)})[1].to_i
      @resource = StashEngine::Resource.find(res_id)
      @resource.update(title: Faker::Hipster.sentence(word_count: 6))
      @resource.authors.first.affiliations = [create(:affiliation)]
      @resource.authors.first.update(author_email: Faker::Internet.email)
      @resource.subjects << create(:subject, subject: Faker::Lorem.unique.word, subject_scheme: 'fos')
      3.times { @resource.subjects << create(:subject, subject: Faker::Lorem.unique.word) }
      @resource.descriptions.type_abstract.first.update(description: Faker::Lorem.paragraph)
      @resource.contributors.first.update(contributor_name: Faker::Company.name)
      Timecop.travel(10.seconds) { @resource.descriptions.type_technical_info.first.update(description: Faker::Lorem.paragraph) }
      refresh
      click_button 'Related works'
      fill_in 'DOI or other URL', with: Faker::Pid.doi
      navigate_to_review
    end

    context :change_log do
      before(:each) do
        sign_out
        sign_in(curator)
        visit activity_log_path(id: @resource.identifier_id)
      end

      it 'shows the metadata log with correct contents' do
        find('button[aria-label="Metadata changes"]').click
        within(:css, "#metadata_table_#{@resource.id} tbody") do
          expect(page).to have_text('Submission title:')
          expect(page).to have_text(CGI.unescapeHTML(@resource.title.html_safe))
          expect(page).to have_text('Set author information:')
          expect(page).to have_text(@resource.authors.first.author_orcid)
          expect(page).to have_text('Subject list:')
          expect(page).to have_text('Updated abstract')
          expect(page).to have_text('Set funder:')
          expect(page).to have_text(@resource.funders.first.contributor_name)
          expect(page).to have_text('Updated README')
          expect(page).to have_text('Set related work:')
          expect(page).to have_text('https://doi.org/')
          expect(page).to have_text('Accepted Dryad terms and conditions')
        end
        # expand descriptions
        within(:css, "#metadata_table_#{@resource.id} tbody") do
          all('.desc-changes-button').first.click
          expect(all('.desc-changes').first).to have_text(@resource.descriptions.find_by(description_type: 'abstract').description)
          all('.desc-changes-button').last.click
          expect(all('.desc-changes').last).to have_text(@resource.descriptions.find_by(description_type: 'technicalinfo').description)
        end
      end
    end

    context :file_change_log do
      it 'shows the correct file log including renamed files' do
        click_button 'Files'
        add_required_data_files
        click_button 'Rename file valid.csv'
        fill_in 'Rename file valid.csv', with: 'super-valid'
        click_button 'Save new name for valid.csv'
        expect(page).to have_text('All progress saved')
        expect(page).to have_text('super-valid.csv')
        click_button 'Preview changes'
        sign_out
        sign_in(curator)
        visit activity_log_path(id: @resource.identifier_id)
        find('button[aria-label="File changes"]').click
        expect(find("#files_table_#{@resource.id}")).to have_text('Created: README.md')
        expect(find("#files_table_#{@resource.id}")).to have_text('Created: valid.csv (501 B)')
        expect(find("#files_table_#{@resource.id}")).to have_text('Renamed valid.csv → super-valid.csv')
      end
    end

    context :new_version do
      before(:each) do
        click_button 'Files'
        add_required_data_files
        click_button 'Preview changes'
        click_button 'Compliance'
        fill_in_validation
        submit_form
        expect(page).to have_content('My datasets')
        sign_out
        create(:curation_activity, status: 'submitted', resource: @resource)
        @resource.current_state = 'submitted'
        @resource.reload
        sign_in(curator)
        visit admin_dashboard_path
        click_button 'Edit dataset'
        expect(page).to have_content('Dataset submission')
        @new_id = page.current_path.match(%r{submission/(\d+)})[1].to_i
      end

      it 'shows the correct new version logs' do
        # displays deleted files
        click_button 'Files'
        click_button 'Remove file'
        expect(page).to have_text('All progress saved')
        expect(page).to have_text('valid.csv removed')
        visit activity_log_path(id: @resource.identifier_id)
        find('button[aria-label="All file changes"]').click
        expect(page).to have_text('Deleted: valid.csv')

        # shows the metadata log with no contents
        find('button[aria-label="All metadata changes"]').click
        within(:css, "#metadata_table_#{@new_id} tbody") do
          expect(page).not_to have_css('tr')
        end
      end
    end
  end
end
