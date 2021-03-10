require_dependency 'stash_engine/application_controller'
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
      @queue_rows = RepoQueueState.latest_per_resource.where.not(state: 'completed').order(helpers.sortable_table_order)
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

    # it is a little weird that these are GET instead of POST requests, but we may want to make it simple to use these URLs from curl or elsewhere
    def graceful_shutdown
      FileUtils.touch(HOLD_SUBMISSIONS_PATH)
      render 'action_taken'
    end

    def graceful_start
      FileUtils.rm(HOLD_SUBMISSIONS_PATH) if File.exist?(HOLD_SUBMISSIONS_PATH)
      resource_ids = RepoQueueState.latest_per_resource.where(state: 'rejected_shutting_down')
        .where(hostname: StashEngine.repository.class.hostname).order(:updated_at).map(&:resource_id)
      enqueue_submissions(resource_ids: resource_ids)
      render 'action_taken'
    end

    def ungraceful_start
      FileUtils.rm(HOLD_SUBMISSIONS_PATH) if File.exist?(HOLD_SUBMISSIONS_PATH)
      resource_ids = RepoQueueState.latest_per_resource.where(state: %w[rejected_shutting_down enqueued])
        .where(hostname: StashEngine.repository.class.hostname).order(:updated_at).map(&:resource_id)
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
