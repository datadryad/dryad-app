# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_software'
require 'byebug'
require 'fileutils'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    # the resource loads the resource and does all the steps to replicate it and looks at some states and saves errors

    # this more or less calls every step in sequence needed to replicate an object and will be a nightmare to test.
    # Skipping testing of the individual steps since they are all tested separately in their own tests, but just
    # testing items unique to this class such writing errors and managing enforcement of queue states.
    RSpec.describe Copier do

      before(:each) do
        @resource = create(:resource)
        @zc = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'software')
        @zsr = Stash::ZenodoSoftware::Copier.new(copy_id: @zc.id)
        @file = create(:software_upload, resource_id: @resource.id)
        my_path = @file.calc_file_path[0..-(File.basename(@file.calc_file_path).length + 1)]
        FileUtils.mkdir_p(my_path)
        FileUtils.touch(@file.calc_file_path)
      end

      after(:each) do
        my_path = @file.calc_file_path[0..-(File.basename(@file.calc_file_path).length + 1)]
        FileUtils.rm_rf(my_path)
      end

      describe '#add_to_zenodo' do
        it 'begins replication for an item that is enqueued correctly' do
          # it gets past initial checks and starts doing http requests
          expect { @zsr.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
        end

        it "it doesn't begin replication if not a software item enqueued correctly" do
          @zc.destroy
          @zc = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'data')
          @zsr = Stash::ZenodoSoftware::Copier.new(copy_id: @zc.id)
          @zsr.add_to_zenodo
          @zc.reload
          expect(@zc.state).to eq('error')
        end

        it 'increments the retries counter' do
          expect { @zsr.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
          zc = @resource.zenodo_copies.software.first
          zc.reload
          expect(zc.retries).to eq(1) # this has been incremented from 0 to 1 when it started attempting adding to zenodo
        end

        it 'rejects submission of an errored submission (needs to be enqueued)' do
          @zc.update(state: 'error')
          @zsr.add_to_zenodo
          # if it had attempted any requests, we'd have webmock request errors
          @zc.reload
          expect(@zc.state).to eq('error')
          expect(@zc.error_info).to include('Cannot replicate a version while a previous version is replicating or has an error')
        end

        it "rejects later submission for one that has previous errored that hasn't been corrected" do
          @zc.update(state: 'error')
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource2.identifier,
                                      deposition_id: @zc.deposition_id, copy_type: 'software')
          @zsr2 = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
          @zsr2.add_to_zenodo
          @zc2.reload
          expect(@zc2.state).to eq('error')
          expect(@zc2.error_info).to include('Cannot replicate a version while a previous version is replicating or has an error')
        end

        it 'rejects submission of something already replicating' do
          @zc.update(state: 'replicating')
          @zsr = Stash::ZenodoSoftware::Copier.new(copy_id: @zc.id)
          @zsr.add_to_zenodo
          # if it had attempted any requests, we'd have webmock request errors
          @zc.reload
          expect(@zc.state).to eq('error')
          expect(@zc.error_info).to include('You should never start replicating unless starting from an enqueued state')
        end

        it 'rejects an out-of-order replication for the same identifier with one deferred' do
          @zc.update(state: 'deferred')
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource.identifier, copy_type: 'software')
          @zsr = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
          @zsr.add_to_zenodo
          @zc2.reload
          expect(@zc2.state).to eq('error')
          expect(@zc2.error_info).to include('Items must replicate in order')
        end

        it 'rejects an out-of-order replication for the same identifier later replicating first' do
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource.identifier, copy_type: 'software')
          @zsr = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
          @zsr.add_to_zenodo
          @zc2.reload
          expect(@zc2.state).to eq('error')
          expect(@zc2.error_info).to include('Items must replicate in order')
        end

        it 'rejects multiple replications for the same resource and type (software)' do
          @zc.update(state: 'finished')
          @zc2 = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'software')
          @zsr2 = Stash::ZenodoSoftware::Copier.new(copy_id: @zc2.id)
          @zsr2.add_to_zenodo
          @zc2.reload
          expect(@zc2.state).to eq('error')
          expect(@zc2.error_info).to include('Only one replication of the same type')
        end

        it 'returns early with info if trying to replicate something with no software' do
          @file.destroy
          @zsr.add_to_zenodo
          @zc.reload
          expect(@zc.state).to eq('finished')
          expect(@zc.error_info).to start_with('No software to submit')
        end
      end
    end
  end
end
