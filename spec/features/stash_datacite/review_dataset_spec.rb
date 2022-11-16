require 'rails_helper'
require 'pry-remote'

RSpec.feature 'ReviewDataset', type: :feature do

  include DatasetHelper
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Tenant

  before(:each) do
    mock_solr!
    mock_tenant!
    mock_repository!
    @user = create(:user)
    sign_in(@user)
  end

  context :requirements_not_met do
    it 'should disable submit button', js: true do
      start_new_dataset
      navigate_to_review
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).to be_disabled
    end

  end

  context :requirements_met, js: true do

    before(:each) do
      start_new_dataset
      fill_required_fields
      navigate_to_review
      agree_to_everything
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

  context :peer_review_section do

    it 'should be visible', js: true do
      start_new_dataset
      navigate_to_review
      expect(page).to have_content('Enable Private for peer review')
    end

  end

  context :software_fileed do
    before(:each, js: true) do
      # Sign in and create a new dataset
      visit root_path
      click_link 'My datasets'
      start_new_dataset
      fill_required_fields

      # Sets this up as a page that can see the software/supp info upload page. There is only one identifier created for this test.
      se_identifier = StashEngine::Identifier.all.first
      StashEngine::InternalDatum.create(identifier_id: se_identifier.id, data_type: 'publicationISSN', value: '1687-7667')
      se_identifier.reload
      navigate_to_upload # so the menus refresh to show newly-allowed tab for special zenodo uploads
    end

    # I do not know how we test this entire flow when it involves the outside S3 service from the page that is hard to mock
    # I think we will need to add requests tests for more specific things for these calls
    xit 'shows the software/supp info if uploaded', js: true do
      navigate_to_software_file
      page.attach_file(Rails.root.join('spec', 'fixtures', 'http_responses', 'favicon.ico')) do
        page.find('#choose-the-files').click
      end
      expect(page).to have_content('favicon.ico')
      check('confirm_to_upload')
      click_on('upload_all')

      # it shows upload complete
      expect(page).to have_content('Upload complete')

      click_on('Proceed to review')
      expect(page).to have_content('Software Files Hosted by Zenodo')
      expect(page).to have_content('favicon.ico')
      # expect(page).to have_content('Select license for files')
    end

    xit "doesn't show the software info if software not uploaded", js: true do
      navigate_to_software_file

      click_on('Proceed to review')
      expect(page).not_to have_content('Software Files Hosted by Zenodo')
      expect(page).not_to have_content('favicon.ico')
      # expect(page).not_to have_content('Select license for files')
    end

    xit 'sets MIT License for software at Zenodo', js: true do
      navigate_to_software_file
      page.attach_file(Rails.root.join('spec', 'fixtures', 'http_responses', 'favicon.ico')) do
        page.find('#choose-the-files').click
      end
      expect(page).to have_content('favicon.ico')
      check('confirm_to_upload')
      click_on('upload_all')

      # it shows upload complete
      expect(page).to have_content('Upload complete')

      click_on('Proceed to review')
      # type hidden -- software_license 'MIT'
      v = find('#software_license', visible: false).value
      expect(v).to eq('MIT')
    end
  end

  context :edit_link do
    it 'opens a page with an edit link and redirects when complete', js: true do
      @identifier = create(:identifier)
      @identifier.edit_code = Faker::Number.number(digits: 5)
      @identifier.save
      @res = create(:resource, identifier: @identifier)
      create(:data_file, file_state: 'copied', resource: @res, upload_file_name: 'README.md')
      create(:data_file, file_state: 'copied', resource: @res)
      # Edit link for the above dataset, including a returnURL that should redirect to a documentation page
      visit "/stash/edit/#{@identifier.identifier}/#{@identifier.edit_code}?returnURL=%2Fstash%2Fsubmission_process"
      all('[id^=instit_affil_]').last.set('test institution')
      navigate_to_review
      agree_to_everything
      fill_in 'user_comment', with: Faker::Lorem.sentence
      submit = find_button('submit_dataset', disabled: :all)
      submit.click
      expect(page.current_path).to eq('/stash/submission_process')
    end
  end

end
