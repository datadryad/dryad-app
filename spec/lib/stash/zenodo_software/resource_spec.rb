# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_software'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    # the resource loads the resource and does all the steps to replicate it and looks at some states and saves errors

    # this more or less calls every step in sequence needed to replicate an object and will be a nightmare to test.
    # Skipping testing of the individual steps since they are all tested separately in their own tests, but just
    # testing items unique to this class such writing errors and managing enforcement of queue states.
    RSpec.describe Resource do

      before(:each) do
        @resource = create(:resource)
        @zc = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'software')
        @zsr = Stash::ZenodoSoftware::Resource.new(resource: @resource)
      end

      describe '#add_to_zenodo' do
        it 'begins replication for an item that is enqueued correctly' do
          # it gets past initial checks and starts doing http requests
          expect { @zsr.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
        end

        it "it doesn't begin replication if not a software item enqueued correctly and it logs error" do
          @zc.destroy
          @zc = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier, copy_type: 'data')
          @zsr = Stash::ZenodoSoftware::Resource.new(resource: @resource)
          expect { @zsr.add_to_zenodo }.not_to raise_error
          expect(@resource.zenodo_copies.software.last.state).to eq('error')
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
          expect(@zc.error_info).to include('You should never start replicating unless starting from an enqueued state')
        end

        it "rejects later submission for one that has previous errored that hasn't been corrected" do
          @zc.update(state: 'error')
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource2.identifier,
                                       deposition_id: @zc.deposition_id, copy_type: 'software')
          @zsr2 = Stash::ZenodoSoftware::Resource.new(resource: @resource2)
          @zsr2.add_to_zenodo
          @zc2.reload
          expect(@zc2.state).to eq('error')
          expect(@zc2.error_info).to include('Cannot replicate a version while a previous version is replicating or has an error')
        end

        it 'rejects submission of something already replicating' do
          @zc.update(state: 'replicating')
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
          @zsr = Stash::ZenodoSoftware::Resource.new(resource: @resource2)
          @zsr.add_to_zenodo
          @zc2.reload
          expect(@zc2.state).to eq('error')
          expect(@zc2.error_info).to include('Items must replicate in order')
        end

        it 'rejects an out-of-order replication for the same identifier later replicating first' do
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @zc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource.identifier, copy_type: 'software')
          @zsr = Stash::ZenodoSoftware::Resource.new(resource: @resource2)
          @zsr.add_to_zenodo
          @zc2.reload
          expect(@zc2.state).to eq('error')
          expect(@zc2.error_info).to include('Items must replicate in order')
        end
      end
    end
  end
end
