require 'rails_helper'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe SubmissionQueueController, type: :request do
    include GenericFilesHelper # this is a bit weird but has a method for creating user needed for UI

    before(:each) do
      generic_before # adds a superuser for use by the following mock
      # HACK: in session because requests specs don't allow session in rails 4
      allow_any_instance_of(SubmissionQueueController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe '#graceful_start' do
      before(:each) do
        # @resource is already set up by generic_before
        resource2 = create(:resource, user_id: @user.id)
        resource2.current_resource_state.update(resource_state: 'submitted')
        @resources = [@resource, resource2]

        @resources.each do |res|
          create(:repo_queue_state, resource: res, state: 'enqueued', hostname: 'test')
          create(:repo_queue_state, resource: res, state: 'processing', hostname: 'test')
          create(:repo_queue_state, resource: res, state: 'errored', hostname: 'test')
        end
      end

      it 'takes a list of resource IDs, updates queue states and calls to re-enqueue them' do
        @url = Rails.application.routes.url_helpers.graceful_start_path({ ids: @resources.map(&:id).join(',') })
        allow_any_instance_of(SubmissionQueueController).to receive(:enqueue_submissions).and_return('')
        response_code = get @url
        expect(response_code).to eql(200)
        @resources.each do |res|
          res.reload
          expect(res.repo_queue_states.length).to eq(1)
          expect(res.repo_queue_states.first.state).to eq('rejected_shutting_down')
        end
      end
    end
  end
end
