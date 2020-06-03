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

  # the fake share copy of the landing page is now gone because the email process has changed
end
