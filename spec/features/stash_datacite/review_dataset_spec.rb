require 'rails_helper'
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
    mock_repository!
    @user = create(:user)
    sign_in(@user)
  end

  context :requirements_not_met do

    it 'submit button should be disabled', js: true do
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

  context :peer_review_section do

    it 'should be visible', js: true do
      start_new_dataset
      navigate_to_review
      expect(page).to have_content('Enable Private for Peer Review')
    end

  end

  context :edit_link do
    it 'opens a page with an edit link and redirects when complete', js: true do
      @identifier = create(:identifier)
      @identifier.edit_code = Faker::Number.number(digits: 5)
      @identifier.save
      @res = create(:resource, identifier: @identifier)

      # Edit link for the above dataset, including a returnURL that should redirect to a documentation page
      visit "/stash/edit/#{@identifier.identifier}/#{@identifier.edit_code}?returnURL=%2Fstash%2Fsubmission_process"
      navigate_to_review
      agree_to_everything
      fill_in 'user_comment', with: Faker::Lorem.sentence
      submit = find_button('submit_dataset', disabled: :all)
      submit.click
      expect(page).to have_content('General reminders and suggestions for publishing')
    end
  end

end
