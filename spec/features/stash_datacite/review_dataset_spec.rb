require 'rails_helper'

RSpec.feature 'ReviewDataset', type: :feature do

  include DatasetHelper

  before(:all) do
    # Start Solr - shutdown is handled globally when all tests have finished
    SolrInstance.instance
  end

  before(:each) do
    @user = create(:user)
    @resource = create(:resource, :submitted, user: @user, identifier: create(:identifier))
    sign_in(@user)
    navigate_to_review
  end

  context :requirements_not_met do

    it 'submit button should be disabled' do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).to be_disabled
    end

  end

  context :requirements_met do

    before(:each) do
      fill_required_fields
    end

    it 'submit button should be enabled' do
      submit = find_button('submit_dataset', disabled: :all)
      expect(submit).not_to be_nil
      expect(submit).not_to be_disabled
    end

    it 'submits' do
      expect(StashEngine.repository).to receive(:submit).with(resource_id: @resource.id)
      submit = find_button('submit_dataset', disabled: :all)
      submit.click
      expect(page).to have_content('My Datasets')
      expect(page).to have_content @resource.title
    end

  end

end
