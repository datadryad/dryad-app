require 'rails_helper'
RSpec.feature 'ResearchFacilityAutofill', type: :feature do

  include DatasetHelper
  include Mocks::RSolr
  include Mocks::Tenant
  include Mocks::Salesforce

  before(:each) do
    mock_solr!
    mock_tenant!
    mock_salesforce!
    @user = create(:user)
    sign_in(@user)
  end

  context :ror_api do

    before(:each) do
      start_new_dataset
    end

    it 'saves a non-selected, typed item to the database', js: true do
      fill_in 'research_facility', with: "Calling All Cats\t"
      click_link 'Review and submit'
      expect(page).to have_text('Research Facility: Calling All Cats')
    end

    # this is hacky since it calls live api.  No easy way to mock it here since request is happening from Javascript now.
    # It seems unreliable, so disabling it.
    xit 'completes name and saves it' do
      item = fill_in 'research_facility', with: 'University of California Sys'
      sleep 3
      item.native.send_keys :arrow_down
      sleep 0.5
      item.native.send_keys :enter
      click_link 'Review and submit'
      expect(page).to have_text('Research Facility: University of California System')
    end
  end
end
