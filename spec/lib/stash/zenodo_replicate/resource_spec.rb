# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    # the resource loads the resource and does all the steps to replicate it and looks at some states and saves errors

    # this more or less calls every step in sequence needed to replicate an object and will be a nightmare to test.
    # Skipping testing of the individual steps since they are all tested separately in their own tests, but just
    # testing items unique to this class such writing errors and managing enforcement of queue states.
    RSpec.describe Resource do

      before(:each) do
        @resource = create(:resource)
        @ztc = create(:zenodo_third_copy, resource: @resource, identifier: @resource.identifier)
        @szr = Stash::ZenodoReplicate::Resource.new(resource: @resource)
      end

      describe '#add_to_zenodo' do
        it 'does something for items in a correct queue state (enqueued)' do
          # it gets past initial checks and starts doing http requests
          expect { @szr.add_to_zenodo }.to raise_error(WebMock::NetConnectNotAllowedError)
        end

        it 'rejects submission of an errored submission (needs to be enqueued)' do
          @ztc.update(state: 'error')
          @szr.add_to_zenodo
          # if it had attempted any requests, we'd have webmock request errors
          @ztc.reload
          expect(@ztc.state).to eq('error')
          expect(@ztc.error_info).to include('You should never start replicating unless starting from an enqueued state')
          # note error logging is also tested in here
        end

        it "rejects later submission for one that has previous errored that hasn't been corrected" do
          @ztc.update(state: 'error')
          @resource2 = create(:resource, identifier_id: @resource.identifier_id)
          @ztc2 = create(:zenodo_third_copy, resource: @resource2, identifier: @resource2.identifier,
                                             deposition_id: @ztc.deposition_id)
          @szr2 = Stash::ZenodoReplicate::Resource.new(resource: @resource2)
          @szr2.add_to_zenodo
          @ztc2.reload
          expect(@ztc2.state).to eq('error')
          expect(@ztc2.error_info).to include('Cannot replicate a version while a previous version is replicating or has an error')
          # note error logging is also tested in here
        end

        it 'rejects submission of something already replicating' do
          @ztc.update(state: 'replicating')
          @szr.add_to_zenodo
          # if it had attempted any requests, we'd have webmock request errors
          @ztc.reload
          expect(@ztc.state).to eq('error')
          expect(@ztc.error_info).to include('You should never start replicating unless starting from an enqueued state')
          # note error logging is also tested in here
        end
      end
    end
  end
end
