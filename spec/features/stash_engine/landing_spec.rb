require 'byebug'
require_relative '../../requests/stash_engine/download_helpers'

RSpec.feature 'Landing', type: :feature, js: true do

  include MerrittHelper
  include DatasetHelper
  include DatabaseHelper
  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Salesforce
  include Mocks::Stripe
  include Mocks::Counter

  before(:each) do
    # kind of crazy to mock all this, but creating identifiers and the curation activity of published triggers all sorts of stuff
    mock_repository!
    mock_solr!
    mock_datacite!
    mock_salesforce!
    mock_stripe!
    mock_counter!

    # below will create @identifier, @resource, @user and the basic required things for an initial version of a dataset
    create_basic_dataset!
    @resource.identifier.update(pub_state: 'published')
    @resource.current_resource_state.update(resource_state: 'submitted')
    @resource.reload
    @token = create(:download_token, resource_id: @resource.id, available: Time.new + 5.minutes.to_i)
    create(:counter_stat, identifier_id: @resource.identifier.id)
  end

  it 'shows the share icons, metrics when published' do
    res = @identifier.resources.first
    res.update(meta_view: true, file_view: true, publication_date: Time.new)
    visit stash_url_helpers.landing_show_path(id: @identifier.to_s)
    expect(page).to have_text('Share:')
    expect(page).to have_text(/\d* downloads/)
  end

  # we don't do a popup for this anymore, just assemble our own zip package in JS
  xit 'shows popup for download in progress' do
    res = @identifier.resources.first
    res.update(meta_view: true, file_view: true, publication_date: Time.new)
    create(:curation_activity, status: 'curation', user_id: @user.id, resource_id: res.id)
    visit stash_url_helpers.landing_show_path(id: @identifier.to_s)
    click_on 'Download full dataset'
    stub_request(:head, %r{https://a-merritt-test-bucket.s3.us-west-2.amazonaws.com/ark+.})
      .to_return(status: 200, body: '', headers: {})
    expect(page).to have_text('Download in progress')
  end

  # packages are now assembled on the client with javascript, remaining 2 tests not needed
  xit "shows popup telling people of problems if download assembly times out but status doesn't" do
    res = @identifier.resources.first
    res.update(meta_view: true, file_view: true, publication_date: Time.new)
    create(:curation_activity, status: 'curation', user_id: @user.id, resource_id: res.id)
    stub_404_status # the status of the token (not found)
    stub_408_assemble # the status for assembly
    visit stash_url_helpers.landing_show_path(id: @identifier.to_s)
    click_on 'Download full dataset'
    expect(page).to have_text('There was a problem assembling your download request')
    click_on 'cancel_dialog'
    expect(page).not_to have_text('There was a problem assembling your download request')
  end

  xit 'shows popup telling people of problems if token status times out' do
    res = @identifier.resources.first
    res.update(meta_view: true, file_view: true, publication_date: Time.new)
    create(:curation_activity, status: 'curation', user_id: @user.id, resource_id: res.id)
    stub_408_status # the status for assembly
    visit stash_url_helpers.landing_show_path(id: @identifier.to_s)
    click_on 'Download full dataset'
    expect(page).to have_text('There was a problem assembling your download request')
    click_on 'cancel_dialog'
    expect(page).not_to have_text('There was a problem assembling your download request')
  end
end
