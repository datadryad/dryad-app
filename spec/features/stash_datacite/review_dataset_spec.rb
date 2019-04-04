require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.feature 'ReviewDataset', type: :feature do

  include DatasetHelper
  include Mocks::Repository
  include Mocks::RSolr

  before(:each) do
    mock_solr!
    @user = create(:user)
    sign_in(@user)
    start_new_dataset
    navigate_to_review
  end

  context :requirements_not_met do

    it 'submit button should be disabled', js: true do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).to be_disabled
    end

  end

  context :requirements_met do

    before(:each) do
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
      expect(page).to have_content(StashEngine::Resource.last.title, wait: 10)
      expect(page).to have_content('submitted with DOI')
    end

  end

end
# rubocop:enable Metrics/BlockLength
