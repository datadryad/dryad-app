# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_software'
require 'byebug'
require 'fileutils'
require_relative 'webmocks_helper'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    # the resource loads the resource and does all the steps to replicate it and looks at some states and saves errors

    # this more or less calls every step in sequence needed to replicate an object and will be a nightmare to test.
    # Skipping testing of the individual steps since they are all tested separately in their own tests, but just
    # testing items unique to this class such writing errors and managing enforcement of queue states.
    RSpec.describe Copier do
      include WebmocksHelper # drops the helper methods for the class into the testing instance

      before(:each) do
        @resource = create(:resource)
        @zc = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'software')
        @zsc = Stash::ZenodoSoftware::Copier.new(copy_id: @zc.id)
        @file = create(:software_upload, resource_id: @resource.id)
        FileUtils.mkdir_p(my_path)
        WebMock.disable_net_connect!(allow_localhost: true)
      end

      describe '#add_to_zenodo' do
        describe 'software prerequisites for submission' do
          xit 'begins replication for an item that is enqueued correctly' do
            # it gets past initial checks and starts doing http requests
            expect { @zsc.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
          end

          xit "it doesn't begin replication if not a software item enqueued correctly" do
            @zc.destroy
            @zc = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'data')
            @zsc = Stash::ZenodoSoftware::Copier.new(copy_id: @zc.id)
            @zsc.add_to_zenodo
            @zc.reload
            expect(@zc.state).to eq('error')
          end

          xit 'rejects submission of an errored submission (needs to be enqueued)' do
            @zc.update(state: 'error')
            @zsc.add_to_zenodo
            # if it had attempted any requests, we'd have webmock request errors
            @zc.reload
            expect(@zc.state).to eq('error')
            expect(@zc.error_info).to include('Cannot replicate a version while a previous version is replicating or has an error')
          end

          xit "rejects later submission for one that has previous errored that hasn't been corrected" do
            @zc.update(state: 'error')
            @resource2 = create(:resource, identifier_id: @resource.identifier_id)
            @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource2.identifier,
                                        deposition_id: @zc.deposition_id, copy_type: 'software')
            @zsc2 = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
            @zsc2.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('error')
            expect(@zc2.error_info).to include('Cannot replicate a version while a previous version is replicating or has an error')
          end

          xit 'rejects submission of something already replicating' do
            @zc.update(state: 'replicating')
            @zsc = Stash::ZenodoSoftware::Copier.new(copy_id: @zc.id)
            @zsc.add_to_zenodo
            # if it had attempted any requests, we'd have webmock request errors
            @zc.reload
            expect(@zc.state).to eq('error')
            expect(@zc.error_info).to include('You should never start replicating unless starting from an enqueued state')
          end

          xit 'rejects an out-of-order replication for the same identifier with one deferred' do
            @zc.update(state: 'deferred')
            @resource2 = create(:resource, identifier_id: @resource.identifier_id)
            @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource.identifier, copy_type: 'software')
            @zsc = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
            @zsc.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('error')
            expect(@zc2.error_info).to include('Items must replicate in order')
          end

          xit 'rejects an out-of-order replication for the same identifier later replicating first' do
            @resource2 = create(:resource, identifier_id: @resource.identifier_id)
            @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource.identifier, copy_type: 'software')
            @zsc = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
            @zsc.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('error')
            expect(@zc2.error_info).to include('Items must replicate in order')
          end

          xit 'rejects a data submission that is supposed to be software submission' do
            # I need to add the following item to get it past a different prerequisite for a different count
            @resource.zenodo_copies << create(:zenodo_copy, copy_type: 'software', identifier_id: @resource.identifier.id)

            @zc.update(copy_type: 'data')

            @zsc = Stash::ZenodoSoftware::Copier.new(copy_id: @zc.id) # redo the creation of object with changed zenodo_copy

            @zsc.add_to_zenodo
            # if it had attempted any requests, we'd have webmock request errors
            @zc.reload
            expect(@zc.state).to eq('error')
            expect(@zc.error_info). to include('Needs to be of the correct type (software not data)')
          end

          xit 'rejects multiple replications for the same resource and type (software)' do
            @zc.update(state: 'finished')
            @zc2 = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'software')
            @zsc2 = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
            @zsc2.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('error')
            expect(@zc2.error_info).to include('Exactly one replication of the same type')
          end

          xit 'returns early with info if trying to replicate something with no software' do
            @file.destroy
            @zsc.add_to_zenodo
            @zc.reload
            expect(@zc.state).to eq('finished')
            expect(@zc.error_info).to start_with('No software to submit')
          end

          xit "rejects a submission if earlier software versions haven't been replicated" do
            # use the default replication as the earlier version but without any replication info in zenodo_copy table
            @zc.destroy

            @resource2 = create(:resource, identifier_id: @resource.identifier_id)
            @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource2.identifier,
                                        deposition_id: @zc.deposition_id, copy_type: 'software')
            @zsc2 = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
            @zsc2.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('error')
            expect(@zc2.error_info).to include('Cannot replicate a later version until earlier versions with software have replicated')
          end
        end

        xit 'increments the retries counter' do
          expect { @zsc.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
          zc = @resource.zenodo_copies.software.first
          zc.reload
          expect(zc.retries).to eq(1) # this has been incremented from 0 to 1 when it started attempting adding to zenodo
        end

        xit 'changes state to replicating' do
          expect { @zsc.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
          zc = @resource.zenodo_copies.software.first
          zc.reload
          expect(zc.state).to eq('replicating') # this has been incremented from 0 to 1 when it started attempting adding to zenodo
        end

        describe 'publish dataset' do
          before(:each) do
            @zc.update(state: 'finished') # this make it seem the previous software upload for this finished so can publish
            @zc2 = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'software_publish',
                                        deposition_id: @zc.deposition_id)
            @zsc = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
          end

          xit "calls publish dataset if it's that type of operation" do
            stub_get_existing_ds(deposition_id: @zc2.deposition_id)
            expect(@zsc).to receive(:publish_dataset)
            @zsc.add_to_zenodo
          end

          xit 'calls required methods for publishing flow' do
            stub_get_existing_ds(deposition_id: @zc2.deposition_id)
            deposit = @zsc.instance_eval('@deposit', __FILE__, __LINE__) # get at private member variable
            expect(deposit).to receive(:update_metadata)
            expect(deposit).to_not receive(:reopen_for_editing)
            expect(deposit).to receive(:publish)
            @zsc.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('finished')
          end

          xit 'calls to reopen closed (published) for metadata updates and no file changes' do
            @zc2.update(state: 'finished')
            @zc3 = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'software_publish',
                                        deposition_id: @zc.deposition_id)
            @zsc = Stash::ZenodoSoftware::Copier.new(copy_id: @zc3.id)
            stub_get_existing_closed_ds(deposition_id: @zc3.deposition_id)

            deposit = @zsc.instance_eval('@deposit', __FILE__, __LINE__) # get at private member variable
            expect(deposit).to receive(:update_metadata)
            expect(deposit).to receive(:reopen_for_editing)
            expect(deposit).to receive(:publish)
            @zsc.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('finished')
          end

          xit 'updates the deposition and other values (for any type of update)' do
            stub_get_existing_ds(deposition_id: @zc2.deposition_id)
            allow(@zsc).to receive(:publish_dataset).and_return(nil)
            @zsc.add_to_zenodo
            @zc2.reload
            expect(@zc2.conceptrecid).to eq((@zc.deposition_id - 1).to_s)
            expect(@zc2.software_doi).to eq("10.5072/zenodo.#{@zc.deposition_id}")
            expect(@zc2.deposition_id).to eq(@zc.deposition_id)
          end

          xit 'updates the relationship to our record for the zenodo doi' do
            stub_get_existing_ds(deposition_id: @zc2.deposition_id)
            allow(@zsc).to receive(:publish_dataset).and_return(nil)
            @zsc.add_to_zenodo
            expect(@resource.related_identifiers.map(&:related_identifier).first).to eq("https://doi.org/10.5072/zenodo.#{@zc.deposition_id}")
          end
        end

        describe 'metadata-only update' do
          before(:each) do
            @zc.update(state: 'finished') # this make it seem the previous software upload for this finished
            @resource2 = create(:resource)
            @resource.identifier.resources << @resource2
            @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource2.identifier, copy_type: 'software',
                                        deposition_id: @zc.deposition_id)
            @zsc2 = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
            @file2 = create(:software_upload, resource_id: @resource2.id, upload_file_name: @file.upload_file_name,
                                              file_state: 'copied')
            @resource2.reload
          end

          xit 'does nothing for metadata-only update and no previous submissions' do
            @resource_lone = create(:resource)
            @zc_lone = create(:zenodo_copy, resource: @resource_lone, identifier: @resource_lone.identifier, copy_type: 'software')
            @zsc_lone = Stash::ZenodoSoftware::Copier.new(copy_id: @zc_lone.id)
            @zsc_lone.add_to_zenodo
            @zc_lone.reload
            # should not see any webmock errors because it shouldn't try contacting the internet
            expect(@zc_lone.state).to eq('finished')
            expect(@zc_lone.error_info).to include('No software to submit')
          end

          xit "doesn't reopen a done dataset just to write the metadata (when not publishing)" do
            stub_get_existing_closed_ds(deposition_id: @zc2.deposition_id)
            @zsc2.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('finished')
            expect(@zc2.error_info).to include("Warning: metadata wasn't updated")
          end

          xit "updates the metadata for open versions that haven't been published" do
            stub_get_existing_ds(deposition_id: @zc2.deposition_id)
            stub_put_metadata(deposition_id: @zc2.deposition_id)
            @zsc2.add_to_zenodo
            @zc2.reload
            expect(@zc2.state).to eq('finished')
          end
        end

        describe '(regular) file updates' do
          xit 'submits a new dataset for file changes' do
            # expect(File).to exist(@file.calc_file_path)

            deposition_id, bucket_link = stub_new_dataset
            stub_put_metadata(deposition_id: deposition_id)

            file_coll = @zsc.instance_eval('@file_collection', __FILE__, __LINE__)
            expect(file_coll).to receive(:ensure_local_files)
            expect(file_coll).to receive(:synchronize_to_zenodo).with(bucket_url: bucket_link).and_return(nil)

            @zsc.add_to_zenodo
            @zc.reload
            expect(@zc.state).to eq('finished')
            expect(@zc.deposition_id).to eq(deposition_id)
            expect(@zc.software_doi).to eq("10.5072/zenodo.#{deposition_id}")
            expect(@zc.conceptrecid).to eq((deposition_id - 1).to_s)
            # expect(File).not_to exist(@file.calc_file_path)
          end

          describe 'has previous version' do

            before(:each) do
              @zc.update(state: 'finished') # this make it seem the previous software upload for this finished
              @resource2 = create(:resource)
              @resource.identifier.resources << @resource2
              @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource2.identifier, copy_type: 'software',
                                          deposition_id: @zc.deposition_id)
              @zsc2 = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
              @file2 = create(:software_upload, resource_id: @resource2.id, upload_file_name: @file.upload_file_name,
                                                file_state: 'created')
              @resource2.reload
            end

            xit 'updates an open dataset for file changes' do
              deposition_id = @zc2.deposition_id

              bucket_link = stub_get_existing_ds(deposition_id: @zc2.deposition_id)

              deposit = @zsc2.instance_eval('@deposit', __FILE__, __LINE__) # get at private member variable
              expect(deposit).to receive(:update_metadata)

              file_coll = @zsc2.instance_eval('@file_collection', __FILE__, __LINE__)
              expect(file_coll).to receive(:ensure_local_files)
              expect(file_coll).to receive(:synchronize_to_zenodo).with(bucket_url: bucket_link)

              @zsc2.add_to_zenodo
              @zc2.reload
              expect(@zc2.state).to eq('finished')
              expect(@zc2.deposition_id).to eq(deposition_id)
              expect(@zc2.software_doi).to eq("10.5072/zenodo.#{deposition_id}")
              expect(@zc2.conceptrecid).to eq((deposition_id - 1).to_s)
            end

            xit 'creates a new version after publication for file changes' do
              stub_get_existing_closed_ds(deposition_id: @zc2.deposition_id)
              new_deposition_id = stub_new_version_process(deposition_id: @zc2.deposition_id)

              deposit = @zsc2.instance_eval('@deposit', __FILE__, __LINE__) # get at private member variable
              expect(deposit).to receive(:update_metadata)

              file_coll = @zsc2.instance_eval('@file_collection', __FILE__, __LINE__)
              expect(file_coll).to receive(:ensure_local_files)
              expect(file_coll).to receive(:synchronize_to_zenodo)

              @zsc2.add_to_zenodo
              @zc2.reload
              expect(@zc2.state).to eq('finished')
              expect(@zc2.deposition_id).to eq(new_deposition_id)
              expect(@zc2.software_doi).to eq("10.5072/zenodo.#{new_deposition_id}")
              expect(@zc2.conceptrecid).to eq((new_deposition_id - 1).to_s)
            end
          end
        end

      end
    end
  end
end
