require 'rails_helper'

RSpec.feature 'ReviewDataset', type: :feature do

  include DatasetHelper
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::DataFile
  include Mocks::Aws

  before(:each) do
    mock_solr!
    mock_repository!
    mock_salesforce!
    mock_file_content!
    mock_aws!
    @user = create(:user)
    sign_in(@user)
  end

  context :requirements_not_met do
    it 'should disable submit button', js: true do
      start_new_dataset
      navigate_to_review
      submit = find_button('submit_button', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit['aria-disabled'])
    end

  end

  # tests below are very slow

  context :requirements_met, js: true do
    xit 'submit button should be enabled', js: true do
      start_new_dataset
      fill_required_fields
      navigate_to_review
      submit = find_button('submit_button', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit['aria-disabled']).to be false

      # submits
      submit_form
      expect(page).to have_content(StashEngine::Resource.last.title)
      expect(page).to have_content('submitted with DOI')
    end
  end

  context :edit_link do
    xit 'opens a page with an edit link and redirects when complete', js: true do
      @identifier = create(:identifier)
      @identifier.edit_code = Faker::Number.number(digits: 5)
      @identifier.save
      @res = create(:resource, identifier: @identifier)
      create(:data_file, file_state: 'copied', resource: @res, download_filename: 'README.md', upload_file_name: 'README.md')
      create(:data_file, file_state: 'copied', resource: @res)
      create(:description, description_type: 'technicalinfo', resource: @res)
      # Edit link for the above dataset, including a returnURL that should redirect to a documentation page
      visit "/edit/#{@identifier.identifier}/#{@identifier.edit_code}?returnURL=%2Fstash%2Fsubmission_process"
      navigate_to_metadata
      click_button 'Authors'
      all('[id^=instit_affil_]').last.set('test institution')
      page.send_keys(:tab)
      page.has_css?('.use-text-entered')
      all(:css, '.use-text-entered').each { |i| i.set(true) }
      click_button 'Subjects'
      fill_in_keywords
      navigate_to_review
      submit_form
      expect(page.current_path).to eq('/submission_process')
    end
  end

end
