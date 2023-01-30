require 'rails_helper'
# require_relative 'download_
# helpers'
require Rails.root.join('spec', 'support', 'helpers', 'generic_files_helper.rb')
require 'byebug'

module StashEngine
  RSpec.describe MetadataEntryPagesController, type: :request do
    include GenericFilesHelper
    include DatabaseHelper
    include DatasetHelper
    include Mocks::Aws

    before(:each) do
      generic_before # sets up a user and resource
      # HACK: in session because requests specs don't allow session in rails 4
      allow_any_instance_of(MetadataEntryPagesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe '#new_version_from_previous' do
      before(:each) do
        @identifier = @resource.identifier

        # version 1 with files
        @resource1 = @resource
        create(:data_file, resource: @resource1)
        create(:data_file, resource: @resource1)

        # version 2 with files
        @resource2 = create(:resource, identifier: @identifier)
        create(:data_file, resource: @resource2)
        create(:data_file, resource: @resource2)
        sub = create(:resource_state, resource_state: 'submitted', resource: @resource2)
        @resource2.update(current_resource_state_id: sub.id)
        @resource1.reload
        @resource2.reload
      end

      it 'creates new version from older version except for files' do
        response_code = post '/stash/metadata_entry_pages/new_version_from_previous', params: { resource_id: @resource1.id }
        expect(response_code).to eq(302)
        expect(@identifier.resources.count).to eq(3)

        @resource3 = @identifier.resources.last

        # descriptive metadata matches version 1
        expect(@resource3.title).to eq(@resource1.title)
        expect(@resource3.descriptions.first.description).to eq(@resource1.descriptions.first.description)

        # files match version 2 (last version before this)
        expect(@resource2.data_files.map(&:upload_file_name)).to eq(@resource3.data_files.map(&:upload_file_name))
      end
    end

  end
end
