require 'rails_helper'

RSpec.feature 'ReviewAndSubmit', type: :feature, js: true do

  include MerrittHelper
  include DatasetHelper
  include DatabaseHelper
  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Ror
  include Mocks::Stripe
  include Mocks::Aws
  include AjaxHelper

  before(:each) do
    mock_repository!
    mock_solr!
    mock_ror!
    mock_datacite!
    mock_stripe!
    mock_aws!
    ignore_zenodo!
    @author = create(:user, tenant_id: 'dryad')

    ActionMailer::Base.deliveries = []

    # Sign in and create a new dataset
    sign_in(@author)
    visit root_path
    click_link 'My Datasets'
    start_new_dataset
    # fill_required_fields # don't need this if we're not checking metadata and just files
  end

  describe 'Review Files' do
    before(:each) do
      navigate_to_upload
      @resource_id = page.current_path.match(%r{resources/(\d+)/up})[1].to_i
      @resource = StashEngine::Resource.find(@resource_id)
      @file1 = create_data_file(resource_id: @resource_id, url: Faker::Internet.url, status_code: 200)
      @file2 = create_software_file(resource_id: @resource_id, url: Faker::Internet.url, status_code: 200)
      sleep 1
    end

    # TODO: it fails same times. Better to solve this before releasing it again
    xit 'shows right links to edit files' do
      click_link('Review and Submit')
      # wait_for_ajax(15)
      expect(page).to have_link('Edit Files', href: '/stash/resources/1/upload', count: 1)
    end
  end

end
