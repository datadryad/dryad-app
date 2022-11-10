require 'stash_engine/application_controller'
require 'fileutils'

module StashEngine
  class SubmissionQueueController < ApplicationController

    HOLD_SUBMISSIONS_PATH = File.expand_path(File.join(Rails.root, '..', 'hold-submissions.txt')).freeze

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_superuser

    def index
      # When the page first loads, the index view lays out the basic framework, but the
      # table starts empty, and it is immediatly populated by refresh_table. So there is
      # no actual work to do in the index method.
    end

    # rubocop:disable Metrics/AbcSize
    def refresh_table
      params[:sort] = 'updated_at' if params[:sort].blank?
      ord = helpers.sortable_table_order(whitelist:
                                           %w[resource_id state hostname updated_at])
      @queue_rows = RepoQueueState.latest_per_resource.where.not(state: 'completed').order(ord)
      @queued_count = RepoQueueState.latest_per_resource.where(state: 'enqueued').count
      @server_held_count = RepoQueueState.latest_per_resource.where(state: 'rejected_shutting_down')
        .where(hostname: StashEngine.repository.class.hostname).count
      @server_queued_count = RepoQueueState.latest_per_resource.where(state: 'enqueued')
        .where(hostname: StashEngine.repository.class.hostname).count
      @processing_count = RepoQueueState.latest_per_resource.where(state: 'processing').count
      @server_processing_count = RepoQueueState.latest_per_resource.where(state: 'processing')
        .where(hostname: StashEngine.repository.class.hostname).count
      @errored_count = RepoQueueState.latest_per_resource.where(state: 'errored').count
      @day_completed_submissions = RepoQueueState.latest_per_resource.where(state: 'completed').where('created_at > ?', Time.new.utc - 1.day).count
      @holding_submissions = File.exist?(HOLD_SUBMISSIONS_PATH)
      @executor = StashEngine.repository.executor

      # Normally, refresh_table is called by javascript, and only the table is repopulated. However, when the sort order is changed, the
      # SortableTableHelper requests this method as text/html, and the entire page is rebuilt.
      render :index if request.format == 'text/html'
    end
    # rubocop:enable Metrics/AbcSize

    def graceful_start
      resource_ids = params[:ids].split(',')

      resource_ids.each do |res_id|
        # clear out all the previous queue states and start with just the first set to 'rejected_shutting_down'
        RepoQueueState.where(resource_id: res_id).each_with_index do |rqs, idx|
          if idx == 0
            rqs.update(state: 'rejected_shutting_down', hostname: StashEngine.repository.class.hostname) # set up for a re-starting state
          else
            rqs.destroy
          end
        end
      end

      enqueue_submissions(resource_ids: resource_ids)
      render 'action_taken'
    end

    private

    def enqueue_submissions(resource_ids:)
      resource_ids.each do |res_id|
        StashEngine.repository.submit(resource_id: res_id)
      end
    end
  end
end
