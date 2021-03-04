# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'
require 'json'
require_relative '../zenodo_software/webmocks_helper'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe FileChangeList do

      # much simpler class than the other updating one since just replicates standard database change info
      # for each and every version to zenodo
      before(:each) do
        WebMock.disable_net_connect!(allow_localhost: true)
        @resource = create(:resource)
        @created = create(:software_upload, file_state: :created, resource: @resource)
        @carried_over = create(:software_upload, file_state: :copied, resource: @resource)
        @deleted = create(:software_upload, file_state: :deleted, resource: @resource)

        @file_change_list = FileChangeList.new(resource: @resource)
      end

      describe '#upload_list' do
        it 'gives list of newly created to upload' do
          expect(@file_change_list.upload_list).to eq(@resource.software_uploads.newly_created)
        end
      end

      describe '#delete_list' do
        it 'gives list of items to remove' do
          expect(@file_change_list.delete_list).to eq(@resource.software_uploads.deleted_from_version.map(&:upload_file_name))
        end
      end
    end
  end
end
