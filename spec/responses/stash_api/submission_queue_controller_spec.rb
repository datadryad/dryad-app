require 'rails_helper'
require_relative 'helpers'
require 'fixtures/stash_api/metadata'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashApi
  RSpec.describe SubmissionQueueController, type: :request do

    before(:all) do
      @user = create(:user, role: 'superuser')
      @doorkeeper_application = create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
                                                                owner_id: @user.id, owner_type: 'StashEngine::User')
      setup_access_token(doorkeeper_application: @doorkeeper_application)
    end

    # I am not testing queuing working here since this is just read only visibility into what
    # is tested and exposed elsewhere.

    # test queue length being returned
    describe '#length' do
      it 'returns JSON for queue length and executor queue length' do
        get '/api/v2/queue_length', {}, default_authenticated_headers
        output = JSON.parse(response.body).with_indifferent_access
        expect(output[:queue_length]).to be_a(Integer)
        expect(output[:executor_queue_length]).to be_a(Integer)
      end
    end
  end
end
# rubocop:enable
