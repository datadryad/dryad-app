# frozen_string_literal: true

require 'rails_helper'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
# rubocop:disable Metrics/BlockLength
module StashEngine
  RSpec.describe LandingController, type: :request do

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

    it 'creates basic_dataset that is valid with required metadata with factory bot' do
      expect(@resource.identifier).to eq(@identifier)
      expect(@resource.authors).to have(2).items
      expect(@resource.descriptions).to have(1).items
      expect(@resource.authors.first.affiliations).to have(1).items
      expect(@resource.current_resource_state.resource_state).to eq('submitted')
      expect(@resource.curation_activities.last.status).to eq('submitted')
      expect(@resource.stash_version.version).to eq(1)
      expect(@resource.stash_version.merritt_version).to eq(1)
      expect(@resource.file_uploads).to have(1).item
    end

    it 'duplicates the basic dataset for version 2 with metadata' do
      duplicate_resource!(resource: @identifier.resources.last)
      @identifier.reload
      expect(@identifier.resources).to have(2).items
      res = @identifier.resources.last
      expect(res.stash_version.version).to eq(2)
      expect(res.stash_version.merritt_version).to eq(2)
      # this file was copied over from a previous version and isn't a new file
      expect(res.file_uploads.first.file_state).to eq('copied')
      expect(res.file_uploads.first.upload_file_name).to eq(@resource.file_uploads.first.upload_file_name)
    end

    it "doesn't show a submitted but not embargoed/published version of the landing page" do
      get "/stash/dataset/#{@identifier}"
      expect(response).to have_http_status(:not_found)
    end

    it 'shows version of the dataset marked for metadata view' do
      # make first look embargoed and second isn't yet
      res = @identifier.resources.first
      res.update(meta_view: true, publication_date: Time.new + 1.day)
      @identifier.update(pub_state: 'embargoed')
      create(:curation_activity, status: 'embargoed', user_id: @user.id, resource_id: res.id)

      # 2nd resource not seen yet
      duplicate_resource!(resource: @identifier.resources.last)
      res2 = @identifier.resources.last
      res2.update(title: 'Treecats and friends')

      get "/stash/dataset/#{@identifier}"
      expect(response.body).to include(res.title)
      expect(response.body).not_to include(res2.title)
      expect(response.body).to include('This dataset is embargoed')
    end

    it 'shows version of the dataset marked as published' do
      # make first look embargoed and second isn't yet
      res = @identifier.resources.first
      res.update(meta_view: true, file_view: true, publication_date: Time.new)
      @identifier.update(pub_state: 'published')
      create(:curation_activity, status: 'published', user_id: @user.id, resource_id: res.id)

      # 2nd resource not seen yet
      duplicate_resource!(resource: @identifier.resources.last)
      res2 = @identifier.resources.last
      res2.update(title: 'Treecats and friends')
      create(:file_upload, resource_id: res2.id, file_state: 'created')

      get "/stash/dataset/#{@identifier}"
      expect(response.body).to include(res.title)
      expect(response.body).not_to include(res2.title)
      expect(response.body).not_to include('This dataset is embargoed')
      expect(response.body).to include(res.file_uploads.first.upload_file_name)
      # shows old file, but not new file that isn't published yet
      expect(response.body).not_to include(res2.file_uploads.where(file_state: 'created').first.upload_file_name)
    end

  end
end
