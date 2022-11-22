# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'
require 'json'
require_relative '../zenodo_software/webmocks_helper'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    RSpec.describe FileChangeList do

      include Stash::ZenodoSoftware::WebmocksHelper # make these methods available
      include Mocks::Salesforce

      before(:each) do
        WebMock.disable_net_connect!(allow_localhost: true)
        mock_salesforce!
        @resources = []
        @resources << create(:resource)

        # the published status makes this the first published version
        @resources.first.curation_activities <<
          [
            create(:curation_activity_no_callbacks, status: 'curation'),
            create(:curation_activity_no_callbacks, status: 'published')
          ]
        @zenodo_copy = create(:zenodo_copy, resource: @resources.first, identifier: @resources.first.identifier)
      end

      describe '#previous_published_resource' do
        it 'finds previously published resource' do
          second_res = create(:resource, identifier_id: @resources.first.identifier_id) # both under same identifier
          @resources << second_res
          zc = create(:zenodo_copy, resource: second_res, identifier: second_res.identifier)

          stub_existing_files(deposition_id: @resources.last.zenodo_copies.first.deposition_id, filenames: [])
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: zc.id)

          # the first version should be submitted because it has that special published curation activity last
          expect(@fcl.previous_published_resource).to eq(@resources.first)
        end

        it "doesn't find previously published resource" do
          # get rid of published curation activity
          @resources.first.curation_activities.last.destroy!

          second_res = create(:resource, identifier_id: @resources.first.identifier_id) # both under same identifier
          @resources << second_res
          zc = create(:zenodo_copy, resource: second_res, identifier: second_res.identifier)

          stub_existing_files(deposition_id: @resources.last.zenodo_copies.first.deposition_id, filenames: [])
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: zc.id)

          # the first version should be submitted because it has that special published curation activity last
          expect(@fcl.previous_published_resource).to be_nil
        end

        it "doesn't find previously published when withdrawn after publish" do
          # get rid of published curation activity
          @resources.first.curation_activities << create(:curation_activity_no_callbacks, status: 'withdrawn')

          second_res = create(:resource, identifier_id: @resources.first.identifier_id) # both under same identifier
          @resources << second_res
          zc = create(:zenodo_copy, resource: second_res, identifier: second_res.identifier)

          # existing files for the resource already at zenodo from both submissions
          stub_existing_files(deposition_id: @resources.last.zenodo_copies.first.deposition_id, filenames: [])
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: zc.id)

          # the first version should be submitted because it has that special published curation activity last
          expect(@fcl.previous_published_resource).to be_nil
        end
      end

      describe '#published_previously?' do
        it 'shows not published if no results for last published' do
          stub_existing_files(deposition_id: @resources.first.zenodo_copies.first.deposition_id, filenames: [])
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: @zenodo_copy.id)
          allow(@fcl).to receive(:previous_published_resource).and_return([])
          expect(@fcl.published_previously?).to be(false)
        end

        it 'shows published if results for last published' do
          stub_existing_files(deposition_id: @resources.first.zenodo_copies.first.deposition_id, filenames: [])
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: @zenodo_copy.id)
          allow(@fcl).to receive(:previous_published_resource).and_return([])
          expect(@fcl.published_previously?).to be(false)
        end
      end

      describe '#delete_list' do
        it 'gives empty list of files to delete if never published previously' do
          files = [
            create(:data_file, file_state: 'deleted'),
            create(:data_file, file_state: 'deleted')
          ]
          @resources.last.data_files << files
          stub_existing_files(deposition_id: @resources.first.zenodo_copies.first.deposition_id, filenames: [])
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: @zenodo_copy.id)
          allow(@fcl).to receive(:previous_published_resource).and_return([])
          expect([]).to eq(@fcl.delete_list)
        end

        it 'gives list of files to delete from items not present in this version but at zenodo' do
          second_res = create(:resource, identifier_id: @resources.first.identifier_id) # both under same identifier
          @resources << second_res
          zc = create(:zenodo_copy, resource: second_res, identifier: second_res.identifier)

          # add some files
          @resources.first.data_files << [create(:data_file), create(:data_file)]
          @resources.last.data_files << [create(:data_file), create(:data_file)]

          stub_existing_files(deposition_id: @resources.last.zenodo_copies.first.deposition_id,
                              filenames: @resources.first.data_files.map(&:upload_file_name) +
                                @resources.last.data_files.map(&:upload_file_name))
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: zc.id)

          # because the first files show as present in zenodo (from stub), but they are not part of the current files
          expect(@fcl.delete_list).to eq(@resources.first.data_files.map(&:upload_file_name))
        end
      end

      describe '#upload_list' do
        it 'uploads only things that have changed since last submission' do
          second_res = create(:resource, identifier_id: @resources.first.identifier_id) # both under same identifier
          @resources << second_res
          zc = create(:zenodo_copy, resource: second_res, identifier: second_res.identifier)

          # add some files
          first_files = [create(:data_file), create(:data_file)]
          @resources.first.data_files << first_files
          new_files = [create(:data_file), create(:data_file)]
          @resources.last.data_files << ([
            create(:data_file, upload_file_name: first_files[0].upload_file_name, file_state: 'copied'),
            create(:data_file, upload_file_name: first_files[1].upload_file_name, file_state: 'copied')
          ] + new_files)

          stub_existing_files(deposition_id: @resources.last.zenodo_copies.first.deposition_id,
                              filenames: first_files.map(&:upload_file_name))
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: zc.id)

          # only new files since last submission need to be sent
          expect(@fcl.upload_list).to eq(new_files)
        end

        it "uploads everything that isn't at zenodo if the previous submissions don't seem to have uploaded files" do
          second_res = create(:resource, identifier_id: @resources.first.identifier_id) # both under same identifier
          @resources << second_res
          zc = create(:zenodo_copy, resource: second_res, identifier: second_res.identifier)

          # add some files
          first_files = [create(:data_file), create(:data_file)]
          @resources.first.data_files << first_files
          new_files = [create(:data_file), create(:data_file)]
          @resources.last.data_files << ([
            create(:data_file, upload_file_name: first_files[0].upload_file_name, file_state: 'copied'),
            create(:data_file, upload_file_name: first_files[1].upload_file_name, file_state: 'copied')
          ] + new_files)

          stub_existing_files(deposition_id: @resources.last.zenodo_copies.first.deposition_id,
                              filenames: [])
          @fcl = Stash::ZenodoReplicate::FileChangeList.new(resource: @resources.last, zc_id: zc.id)

          # sends all 4 files present in this version, even though two were supposedly uploaded before, but they're not
          # present at zenodo right now, so need to send them, anyway
          expect(@fcl.upload_list).to eq(@resources.last.data_files)
        end
      end
    end
  end
end
