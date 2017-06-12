require 'rails_helper'

RSpec.describe StashEngine::MetadataEntryPagesController, type: :controller do
  routes { StashEngine::Engine.routes }

  logs_in_with 'TEST', 'TESTUSER@GMAIL.COM', 'UCOP.EDU'
  let(:resource) { StashEngine::Resource.create }
  describe 'GET find_or_create' do
    it 'has a 200 status code' do
      get :find_or_create
      expect(response).to render_template('find_or_create')
    end
  end
end
