require 'rails_helper'
require 'byebug'
RSpec.feature 'Landing', type: :feature do

  include MerrittHelper
  include DatasetHelper
  include DatabaseHelper
  include Mocks::Datacite
  include Mocks::Repository
  include Mocks::RSolr
  include Mocks::Ror
  include Mocks::Stripe

  before(:each) do
    # kind of crazy to mock all this, but creating identifiers and the curation activity of published triggers all sorts of stuff
    mock_repository!
    mock_solr!
    mock_ror!
    mock_datacite!
    mock_stripe!

    # below will create @identifier, @resource, @user and the basic required things for an initial version of a dataset
    create_basic_dataset!
  end

  describe 'works correctly with the share fake landing page', js: true do
    it 'shows popup on fake landing page for asych download share' do
      # creates an async download query that is asynchrounous (wait and email to download)
      stub_request(:get, %r{merritt-fake.cdlib.org/async}).with(headers: { 'Accept' => '*/*' }).to_return(status: 200)
      res = @identifier.resources.first
      res.update(meta_view: true, file_view: true, publication_date: Time.new)
      create(:curation_activity, status: 'curation', user_id: @user.id, resource_id: res.id)
      visit stash_url_helpers.share_path(@identifier.shares.first.secret_id)
      expect(page).to have_text('Large File Download Request')
    end
  end
end
