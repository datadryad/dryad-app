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
    @resource.update(meta_view: true, file_view: true, publication_date: Time.new)
    @resource.reload
    @token = create(:download_token, resource_id: @resource.id, available: Time.new + 5.minutes.to_i)
    create(:counter_stat, identifier_id: @resource.identifier.id)    
  end

  it 'shows the share icons, metrics when published' do
    visit stash_url_helpers.landing_show_path(id: @identifier.to_s)
    expect(page).to have_text('Share:')
    expect(page).to have_text(/\d* downloads/)
  end

end
