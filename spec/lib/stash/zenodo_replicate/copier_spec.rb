# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'webmock/rspec'
require 'stash/zenodo_replicate'
require 'byebug'

module Stash
  module ZenodoReplicate
    # the resource loads the resource and does all the steps to replicate it and looks at some states and saves errors

    # this more or less calls every step in sequence needed to replicate an object and will be a nightmare to test.
    # Skipping testing of the individual steps since they are all tested separately in their own tests, but just
    # testing items unique to this class such writing errors and managing enforcement of queue states.
    RSpec.describe Copier do

      before(:each) do
        WebMock.disable_net_connect!(allow_localhost: true)
        @resource = create(:resource)
        @ztc = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier)
        @szr = Stash::ZenodoReplicate::Copier.new(copy_id: @ztc.id)
      end

      describe '#add_to_zenodo' do
        it 'does something for items in a correct queue state (enqueued)' do
          # it gets past initial checks and starts doing http requests
          expect { @szr.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
        end

        it 'increments the retries counter' do
          expect { @szr.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
          zc = @resource.zenodo_copies.data.first
          zc.reload
          expect(zc.retries).to eq(1) # this has been incremented from 0 to 1 when it started attempting adding to zenodo
        end

        it 'rejects submission of an errored submission (needs to be enqueued)' do
          @ztc.update(state: 'error')
          @szr = Stash::ZenodoReplicate::Copier.new(copy_id: @ztc.id)
          @szr.add_to_zenodo
          @ztc.reload
          expect(@ztc.state).to eq('error')
          expect(@ztc.error_info).to include('unless starting from an enqueued state')
          # NOTE: error logging is also tested in here
        end

        it "rejects later submission for one that has previous errored that hasn't been corrected" do
          @ztc.update(state: 'error')
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @ztc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource2.identifier,
                                       deposition_id: @ztc.deposition_id)
          @szr2 = Stash::ZenodoReplicate::Copier.new(copy_id: @ztc2.id)
          @szr2.add_to_zenodo
          @ztc2.reload
          expect(@ztc2.state).to eq('error')
          expect(@ztc2.error_info).to include('Cannot replicate a version while a previous version is replicating or has an error')
          # NOTE: error logging is also tested in here
        end

        it "doesn't reject earlier submission if later one has errored (but earlier is done)" do
          @ztc.update(state: 'finished')
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @ztc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource2.identifier,
                                       deposition_id: @ztc.deposition_id)
          @resource3 = create(:resource, identifier_id: @resource.identifier_id)
          @ztc3 = create(:zenodo_copy, resource: @resource3, identifier: @resource3.identifier,
                                       deposition_id: @ztc.deposition_id, state: 'error')
          @szr2 = Stash::ZenodoReplicate::Copier.new(copy_id: @ztc2.id)
          # it gets through the checks and raises an error trying to do a HTTP request
          expect { @szr2.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
        end

        it 'rejects submission of something already replicating' do
          @ztc.update(state: 'replicating')
          @szr.add_to_zenodo
          # if it had attempted any requests, we'd have webmock request errors
          @ztc.reload
          expect(@ztc.state).to eq('error')
          expect(@ztc.error_info).to include('Cannot replicate a version while a previous version is replicating or has an error')
          # NOTE: error logging is also tested in here
        end

        it 'rejects an out-of-order replication for the same identifier with one deferred' do
          @ztc.update(state: 'deferred')
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @ztc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource.identifier)
          @szr = Stash::ZenodoReplicate::Copier.new(copy_id: @ztc2.id)
          @szr.add_to_zenodo
          @ztc2.reload
          expect(@ztc2.state).to eq('error')
          expect(@ztc2.error_info).to include('Items must replicate in order')
        end

        it 'rejects an out-of-order replication for the same identifier later replicating first' do
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @ztc2 = create(:zenodo_copy, resource: @resource2, identifier: @resource.identifier)
          @szr = Stash::ZenodoReplicate::Copier.new(copy_id: @ztc2.id)
          @szr.add_to_zenodo
          @ztc2.reload
          expect(@ztc2.state).to eq('error')
          expect(@ztc2.error_info).to include('Items must replicate in order')
        end
      end
    end
  end
end
