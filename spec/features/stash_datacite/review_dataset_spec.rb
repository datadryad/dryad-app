require 'rails_helper'
require 'pry-remote'

RSpec.feature 'ReviewDataset', type: :feature do

  include DatasetHelper
  include Mocks::Repository
  include Mocks::Ror
  include Mocks::RSolr
  include Mocks::Tenant

  before(:each) do
    mock_solr!
    mock_ror!
    mock_tenant!
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

  context :requirements_met do

    before(:each) do
      start_new_dataset
      navigate_to_review
      mock_repository!
      fill_required_fields
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
      expect(page).to have_content('Enable Private for Peer Review')
    end

  end

  context :software_license do
    before(:each, js: true) do
      # Sign in and create a new dataset
      visit root_path
      click_link 'My Datasets'
      start_new_dataset
      fill_required_fields
    end

    it 'shows the software license if software uploaded', js: true do
      navigate_to_software_upload
      page.attach_file(Rails.root.join('spec', 'fixtures', 'http_responses', 'favicon.ico')) do
        page.find('#choose-the-files').click
      end
      expect(page).to have_content('favicon.ico')
      check('confirm_to_upload')
      click_on('upload_all')

      # it shows upload complete
      expect(page).to have_content('Upload complete')

      click_on('Proceed to Review')
      expect(page).to have_content('Supporting Information Hosted by Zenodo')
      expect(page).to have_content('favicon.ico')
      expect(page).to have_content('Select license for files')
    end

    it "doesn't show the software license if software not uploaded", js: true do
      navigate_to_software_upload

      click_on('Proceed to Review')
      expect(page).not_to have_content('Supporting Information Hosted by Zenodo')
      expect(page).not_to have_content('favicon.ico')
      expect(page).not_to have_content('Select license for files')
    end

  end

end
