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

  context :requirements_met, js: true do
    it 'submit button should be enabled', js: true do
      start_new_dataset
      fill_required_fields
      navigate_to_review
      submit = find_button('submit_button', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit['aria-disabled']).to be(nil)

      # submits
      submit_form
      expect(page).to have_content(StashEngine::Resource.last.title.html_safe)
      expect(page).to have_content("Your dataset with the DOI #{StashEngine::Resource.last.identifier_uri} was submitted for curation")
    end
  end
end
